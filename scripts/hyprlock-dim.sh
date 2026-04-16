#!/usr/bin/env bash
# Dim LG UltraFine on lock. While locked:
#   - any key (other than Esc) brightens to the saved value
#   - Esc re-dims to 0, preserving the saved value for the next keypress
# On unlock, brightness is always restored to the saved value.
set -u

FALLBACK=54000

get_brightness() { usb-hid-brightness 2>/dev/null | grep -oP '\d+$' | tail -n1; }
set_brightness() { usb-hid-brightness "$1" >/dev/null 2>&1 || true; }

saved="$(get_brightness)"
[[ -z "${saved}" ]] && saved="${FALLBACK}"

set_brightness 0

# Watcher: loops until killed by the EXIT trap. Reads raw evdev events and
# toggles brightness based on key code. Only reacts to key-down (value==1),
# so releases and auto-repeats are ignored at the protocol level.
(
    SAVED="${saved}" python3 - <<'PY'
import glob, os, select, struct, subprocess, sys

EV_FMT = 'qqHHi'                     # struct input_event on 64-bit: 24 bytes
EV_SIZE = struct.calcsize(EV_FMT)
EV_KEY = 0x01
KEY_ESC = 1

saved = os.environ['SAVED']

def set_brightness(val):
    subprocess.run(['usb-hid-brightness', val],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

fds = []
for path in sorted(glob.glob('/dev/input/event*')):
    try:
        fds.append(os.open(path, os.O_RDONLY | os.O_NONBLOCK))
    except OSError:
        pass

if not fds:
    sys.exit(2)

state = 'dim'                        # matches what bash just set
try:
    while True:
        ready, _, _ = select.select(fds, [], [])
        for fd in ready:
            try:
                data = os.read(fd, EV_SIZE * 64)
            except BlockingIOError:
                continue
            for i in range(0, len(data), EV_SIZE):
                _, _, type_, code, value = struct.unpack(EV_FMT, data[i:i+EV_SIZE])
                if type_ != EV_KEY or value != 1:
                    continue
                if code == KEY_ESC:
                    if state != 'dim':
                        set_brightness('0')
                        state = 'dim'
                else:
                    if state != 'bright':
                        set_brightness(saved)
                        state = 'bright'
finally:
    for fd in fds:
        try: os.close(fd)
        except OSError: pass
PY
) &
watcher=$!

cleanup() {
    pkill -TERM -P "${watcher}" 2>/dev/null || true
    kill -TERM "${watcher}" 2>/dev/null || true
    set_brightness "${saved}"
}
trap cleanup EXIT

hyprlock "$@"
