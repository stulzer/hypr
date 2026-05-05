#!/usr/bin/env bash
# Dim LG UltraFine + eDP-1 (when active) on lock. While locked:
#   - any key (other than Esc) brightens both to their saved values
#   - Esc re-dims to 0, preserving the saved values for the next keypress
# On unlock, both monitors are always restored to their saved values.
#
# LG UltraFine: usb-hid-brightness (USB HID, int 0..54000).
# eDP-1: wl-gammarelay-rs over busctl (double 0.0..1.0). Skipped silently if
# the laptop monitor is disabled or the daemon is not running.
set -u

FALLBACK=54000        # LG (int)
EDP_FALLBACK=1        # eDP-1 double, full brightness
EDP_BUS=rs.wl-gammarelay
EDP_OUTPUT=/outputs/eDP_1   # dbus paths can't contain '-'; wl-gammarelay-rs uses '_'
EDP_IFACE=rs.wl.gammarelay

get_lg() { usb-hid-brightness 2>/dev/null | grep -oP '\d+$' | tail -n1; }
set_lg() { usb-hid-brightness "$1" >/dev/null 2>&1 || true; }

# Returns the saved double on success; empty + non-zero exit ⇒ skip eDP.
get_edp() {
    local out
    out="$(busctl --user -- get-property "${EDP_BUS}" "${EDP_OUTPUT}" \
                  "${EDP_IFACE}" Brightness 2>/dev/null)" || return 1
    awk '{print $2}' <<<"$out"   # "d 0.75" → "0.75"
}
set_edp() {
    busctl --user -- set-property "${EDP_BUS}" "${EDP_OUTPUT}" \
        "${EDP_IFACE}" Brightness d "$1" >/dev/null 2>&1 || true
}

saved_lg="$(get_lg)"
[[ -z "${saved_lg}" ]] && saved_lg="${FALLBACK}"
saved_edp="$(get_edp || true)"
[[ -n "${saved_edp}" && ! "${saved_edp}" =~ ^[0-9.]+$ ]] && saved_edp="${EDP_FALLBACK}"

set_lg 0
[[ -n "${saved_edp}" ]] && set_edp 0

# Watcher: loops until killed by the EXIT trap. Reads raw evdev events and
# toggles brightness based on key code. Only reacts to key-down (value==1),
# so releases and auto-repeats are ignored at the protocol level.
(
    SAVED_LG="${saved_lg}" \
    SAVED_EDP="${saved_edp}" \
    EDP_BUS="${EDP_BUS}" \
    EDP_OUTPUT="${EDP_OUTPUT}" \
    EDP_IFACE="${EDP_IFACE}" \
    python3 - <<'PY'
import glob, os, select, struct, subprocess, sys

EV_FMT = 'qqHHi'                     # struct input_event on 64-bit: 24 bytes
EV_SIZE = struct.calcsize(EV_FMT)
EV_KEY = 0x01
KEY_ESC = 1

saved_lg   = os.environ['SAVED_LG']
saved_edp  = os.environ.get('SAVED_EDP') or None     # empty string ⇒ skip eDP
edp_bus    = os.environ['EDP_BUS']
edp_output = os.environ['EDP_OUTPUT']
edp_iface  = os.environ['EDP_IFACE']

def set_lg(val):
    subprocess.run(['usb-hid-brightness', val],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def set_edp(val):
    if saved_edp is None:
        return
    subprocess.run(
        ['busctl', '--user', '--', 'set-property',
         edp_bus, edp_output, edp_iface, 'Brightness', 'd', val],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def go_dim():
    set_lg('0')
    set_edp('0.1')

def go_bright():
    set_lg(saved_lg)
    set_edp(saved_edp or '1')

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
                        go_dim()
                        state = 'dim'
                else:
                    if state != 'bright':
                        go_bright()
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
    set_lg "${saved_lg}"
    [[ -n "${saved_edp}" ]] && set_edp "${saved_edp}"
}
trap cleanup EXIT

hyprlock "$@"
