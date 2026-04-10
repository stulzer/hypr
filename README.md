# Hyprland Config

Personal [Hyprland](https://hypr.land/) configuration for a single external 4K monitor (LG via DP-2 at 3840x2160@60Hz, laptop display disabled).

## Features

- **Dwindle layout** with force-split and pseudotiling
- **ALT-based vim keys** (H/J/K/L) for focus and window movement
- **SUPER remapped to forward Ctrl shortcuts** (Ctrl+L, Ctrl+K, Ctrl+F, etc.) so common app shortcuts work through the compositor
- **Portuguese diacritics** via ALT+key dead-key combos (acute, tilde, cedilla, circumflex, diaeresis, grave)
- **Universal copy/paste** using Ctrl+Insert / Shift+Insert under SUPER+C / SUPER+V
- **Clipboard history** via cliphist + walker
- **Screenshot region to clipboard** with grim + slurp
- **LG monitor brightness** control via usb-hid-brightness (Scroll_Lock/Pause and ALT+Up/Down)
- **Hyprlock** lock screen with blurred screenshot background and Catppuccin-style colors
- **PiP window rule** for floating + pinned picture-in-picture

## Dependencies

### Core

| Package | Description |
|---|---|
| [hyprland](https://github.com/hyprwm/Hyprland) | Wayland compositor |
| [hyprlock](https://github.com/hyprwm/hyprlock) | Lock screen |

### Autostart / Bar

| Package | Description |
|---|---|
| [waybar](https://github.com/Alexays/Waybar) | Status bar |
| [walker](https://github.com/abenz1267/walker) | Application launcher (run with `--gapplication-service`) |

### Clipboard

| Package | Description |
|---|---|
| [wl-clipboard](https://github.com/bugwarrior/wl-clipboard) | `wl-paste` and `wl-copy` utilities |
| [cliphist](https://github.com/sentriz/cliphist) | Clipboard history manager |

### Input / Typing

| Package | Description |
|---|---|
| [wtype](https://github.com/atx/wtype) | Wayland keyboard input (dead keys for diacritics) |

### Screenshots

| Package | Description |
|---|---|
| [grim](https://sr.ht/~emersion/grim/) | Screenshot tool |
| [slurp](https://github.com/emersion/slurp) | Region selection |

### Media / Hardware

| Package | Description |
|---|---|
| [wireplumber](https://pipewire.pages.freedesktop.org/wireplumber/) | Audio control via `wpctl` |
| [playerctl](https://github.com/altdesktop/playerctl) | Media player control |
| [brightnessctl](https://github.com/Hummer12007/brightnessctl) | Laptop backlight brightness |
| [usb-hid-brightness](https://github.com/nicoroeser/usb-hid-brightness) | External monitor brightness via USB HID (for LG displays) |

### Fonts

| Font | Used in |
|---|---|
| [Maple Mono NF](https://github.com/subframe7536/maple-font) | Hyprlock time/date labels |

### Apps (defaults)

| Package | Role |
|---|---|
| [kitty](https://sw.kovidgoez.net/kitty/) | Terminal (`$terminal`) |
| [nautilus](https://apps.gnome.org/Nautilus/) | File manager (`$fileManager`) |

### Optional

| Package | Description |
|---|---|
| hyprshutdown | Graceful shutdown (falls back to `hyprctl dispatch exit`) |

### Symlink working directory

`sudo ln -s ~/.config/hypr/scripts/terminal-cwd.sh /usr/bin/current-working-directory`
