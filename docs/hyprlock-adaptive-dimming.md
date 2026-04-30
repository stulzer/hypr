# Hyprlock Adaptive Dimming — Session Learnings

Notes from designing and debugging a wrapper that dims the LG UltraFine (via
`usb-hid-brightness`) when hyprlock engages and restores brightness on the first
real keypress, with an Esc toggle to re-dim without losing the saved value.

## What was built

- `~/.config/hypr/scripts/hyprlock-dim.sh` — bash wrapper around `hyprlock` that
  drives an inline Python watcher.
- `~/.config/hypr/hyprland.conf:285–286` — both lock keybinds
  (`Super+Ctrl+L` and `Super+Ctrl+Q` → suspend) now call the wrapper.
- `~/.config/hypr/hyprlock.conf:3` — `grace = 0`.

Behaviour during lock:

| Event                            | Action                      |
| -------------------------------- | --------------------------- |
| lock engaged                     | dim to 0 (state = `dim`)    |
| any key-down other than Esc      | restore saved value (`bright`) |
| Esc key-down                     | dim to 0 (`dim`)            |
| unlock (SIGUSR1 or password)     | `EXIT` trap restores saved  |

## Key learnings

### 1. Hyprlock has no lock / unlock / keypress hooks

Only `SIGUSR1` (unlock), `SIGUSR2` (refresh labels), `--immediate`, and the
`no_fade_in` config option. Anything that needs to react to lock state or key
events must be driven externally by wrapping `hyprlock` in a script. There is
no `on_lock`, `on_unlock`, or `on_key_press` directive.

### 2. `libinput` CLI is **not** installed with Hyprland

Hyprland links `libinput` as a library, but the `libinput debug-events` binary
comes from a separate package that is not a Hyprland dependency. On this
system, `command -v libinput` returned nothing. Easy to miss, since the
compositor itself "uses libinput".

### 3. Silent pipe failure is a debugging trap

`missing-cmd | grep -m1 pattern` **does not hang waiting for input** — it
exits instantly. When the first command is not found:

1. The missing command prints "command not found" to stderr and exits.
2. `grep` reads an empty stdin, sees EOF, exits with code 1 (no match).
3. Whatever ran after the pipeline runs immediately.

In this session that made the bug look timing-related: `sleep N; libinput | grep;
restore` appeared as "dim lasts exactly N seconds, then restores out of
nowhere." The delay came from the `sleep`, not from anything in the pipeline.
**Lesson:** when a pipeline exits instantly and behaviour looks like an early
restore, verify every binary in the pipeline exists before chasing subtler
causes.

### 4. Raw evdev is often cleaner than parsing libinput text

Python + `struct.unpack('qqHHi', ...)` on `/dev/input/event*` gives
protocol-level filtering:

- `type == EV_KEY (0x01)` — only keyboard events
- `value == 1` — key-down only (0 = release, 2 = auto-repeat)

No external tools, no grep patterns that can match the wrong line, no output
buffering concerns. `python3` is present on the system by default.

### 5. Fresh fd opens on evdev start from "now"

The kernel buffers input events per-fd. Opening `/dev/input/event*` *after*
the lock keybind has been dispatched means past key-down events for
`Super/Ctrl/L` are not in our buffer — we cannot accidentally consume them.
Only the subsequent release/auto-repeat events are visible, and both are
filtered by `value == 1`. This is why the current watcher needs **no startup
delay** (an earlier `WATCHER_DELAY` guard was a workaround for a different
root cause — the missing `libinput` — and is no longer needed).

### 6. `grace = 3` conflicts with "first keypress brightens"

`grace` makes hyprlock dismiss on *any* input within the window. If left at
the default, the very first keypress would both brighten the screen and
immediately unlock without ever reaching the password field, defeating the
point of the dim UX. Set `grace = 0` when pairing hyprlock with an input
watcher.

### 7. `usb-hid-brightness` is device-agnostic here

The tool auto-detects the LG UltraFine over USB HID — no device ID needed.
Value range on this panel is `0–54000`; existing brightness keybinds
(`hyprland.conf:265–269`) step by `5400` and clamp at the bounds. The wrapper
reuses the same probe pattern:

```bash
usb-hid-brightness | grep -oP '\d+$' | tail -n1
```

### 8. Subshell child cleanup needs `pkill -P` before `kill`

`(pipeline) &` gives `$!` for the subshell, not its pipeline members.
`kill $watcher` terminates the subshell, but its children (e.g. a blocked
`python3` doing `select.select`) become orphans with `PPID=1` and keep
running. The cleanup trap therefore does:

```bash
pkill -TERM -P "${watcher}" 2>/dev/null || true  # children first
kill  -TERM    "${watcher}" 2>/dev/null || true  # then the subshell
```

Otherwise a leftover `python3` watcher could survive across unlocks.

### 9. `EXIT` trap + keypress-watcher = idempotent restore

Whichever path fires first — the watcher detecting a key-down or the trap
firing on hyprlock exit — calls `set_brightness "$saved"` with the same
value. A second call is a no-op from the user's perspective. This makes the
design resilient to all exit paths: correct password, `pkill -USR1 hyprlock`
from another TTY, hyprlock crash, or user typing before unlock.

### 10. Hyprland `exec,` uses `sh -c`

`~` expansion works in keybind paths (`exec, ~/.config/hypr/scripts/...`).
No need to hard-code absolute paths or use `$HOME`.

## Path the design took

1. **v1** — wrapper with `libinput debug-events | grep pressed`, `grace = 3`
   kept. Dimming was partial; suspected keybind key-release leaking into the
   watcher.
2. **v2** — added `WATCHER_DELAY` and anchored the grep to `pressed$` to
   ignore auto-repeat variants. Symptom persisted and matched the delay
   value exactly — the tell that the delay itself was the whole story.
3. **v3** — probed binaries; found `libinput` absent. Switched to inline
   Python + raw evdev. Dim held correctly; first real keypress restored.
4. **v4** — watcher changed from one-shot (exit on first press) to a loop
   with a `dim`/`bright` state machine keyed on `KEY_ESC`. Esc re-dims
   without losing the saved value; hyprlock's native Esc-clears-input
   behaviour aligns nicely with the visual dim.

## Files to keep in sync

- `~/.config/hypr/scripts/hyprlock-dim.sh` — the wrapper.
- `~/.config/hypr/hyprland.conf` — lock keybinds must call the wrapper, not
  `hyprlock` directly.
- `~/.config/hypr/hyprlock.conf` — `grace = 0` must hold for the dim/brighten
  UX to make sense.

## Prerequisites on a fresh machine

- `python3` in `$PATH` (default on Arch).
- Read access to `/dev/input/event*` — normally granted to the active-seat
  user via `uaccess` udev tags under seatd/logind. If ever broken, the
  watcher exits with code 2 and the `EXIT` trap still restores brightness
  on unlock (dim-only mode, no keypress-triggered restore).
- `usb-hid-brightness` installed and able to see the monitor (same
  prerequisite as the existing brightness keybinds).
