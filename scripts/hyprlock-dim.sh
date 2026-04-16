#!/usr/bin/env bash
# Dim LG UltraFine on lock, restore on first keypress or unlock.
set -u

STATE="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-brightness"
FALLBACK=54000

get_brightness() { usb-hid-brightness 2>/dev/null | grep -oP '\d+$' | tail -n1; }
set_brightness() { usb-hid-brightness "$1" >/dev/null 2>&1 || true; }

saved="$(get_brightness)"
[[ -z "${saved}" ]] && saved="${FALLBACK}"
printf '%s\n' "${saved}" > "${STATE}"

set_brightness 0

# Watcher: read raw evdev events from all input devices and exit on the first
# real key-press (EV_KEY with value==1 — releases are 0, auto-repeats are 2).
# The fds are opened AFTER the lock keybind has been handled, so past events
# from Super/Ctrl/L aren't in our buffer.
(
    python3 - <<'PY'
import glob, os, select, struct, sys

EV_FMT = 'qqHHi'                     # struct input_event on 64-bit Linux: 24 bytes
EV_SIZE = struct.calcsize(EV_FMT)
EV_KEY = 0x01

fds = []
for path in sorted(glob.glob('/dev/input/event*')):
    try:
        fds.append(os.open(path, os.O_RDONLY | os.O_NONBLOCK))
    except OSError:
        pass

if not fds:
    sys.exit(2)                      # no permission / no devices — let EXIT trap restore

try:
    while True:
        ready, _, _ = select.select(fds, [], [])
        for fd in ready:
            try:
                data = os.read(fd, EV_SIZE * 64)
            except BlockingIOError:
                continue
            for i in range(0, len(data), EV_SIZE):
                _, _, type_, _, value = struct.unpack(EV_FMT, data[i:i+EV_SIZE])
                if type_ == EV_KEY and value == 1:
                    sys.exit(0)
finally:
    for fd in fds:
        try: os.close(fd)
        except OSError: pass
PY
    rc=$?
    if [[ ${rc} -eq 0 && -r "${STATE}" ]]; then
        set_brightness "$(cat "${STATE}")"
    fi
) &
watcher=$!

cleanup() {
    pkill -TERM -P "${watcher}" 2>/dev/null || true
    kill -TERM "${watcher}" 2>/dev/null || true
    [[ -r "${STATE}" ]] && set_brightness "$(cat "${STATE}")"
    rm -f "${STATE}"
}
trap cleanup EXIT

hyprlock "$@"
