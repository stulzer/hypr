-- Keybinds -- https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "walker"

-- LG monitor backlight over USB-HID, stepping by 5400 and clamping at the ends.
-- Long-bracket literals so the embedded shell quoting (\d+$, $v, &&) needs no
-- escaping.
local lgBrightnessUp   = [[bash -c 'v=$(usb-hid-brightness | grep -oP "\d+$"); v=$((v+5400)); ((v>54000)) && v=54000; usb-hid-brightness $v']]
local lgBrightnessDown = [[bash -c 'v=$(usb-hid-brightness | grep -oP "\d+$"); v=$((v-5400)); ((v<0)) && v=0; usb-hid-brightness $v']]

---------------------------
---- WINDOW NAVIGATION ----
---------------------------

-- Vim-style focus movement. SUPER+K is intentionally not here: it is claimed by
-- the universal CTRL+K passthrough below, which already shadowed this bind under
-- the old .conf. Move that passthrough elsewhere if you want focus-up back.
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }),  { description = "Move focus left" })
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Move focus right" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }),  { description = "Move focus down" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }),  { description = "Move focus up" })

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }),  { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }),  { description = "Move window down" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }),    { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })

hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("kitty btop"),     { description = "open btop" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), { description = "Reload hyprland" })

--------------------------
---- LG MONITOR LIGHT ----
--------------------------

hl.bind("Scroll_Lock", hl.dsp.exec_cmd(lgBrightnessDown), { description = "LG brightness down", repeating = true })
hl.bind("Pause",       hl.dsp.exec_cmd(lgBrightnessUp),   { description = "LG brightness up",   repeating = true })

hl.bind(mainMod .. " + up",   hl.dsp.exec_cmd(lgBrightnessUp),   { description = "LG brightness up",   repeating = true })
hl.bind(mainMod .. " + down", hl.dsp.exec_cmd(lgBrightnessDown), { description = "LG brightness down", repeating = true })

---------------------
---- CORE BINDS  ----
---------------------

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal .. [[ --directory "$(current-working-directory)"]]))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- hyprshutdown is not installed, so the fallback branch is the live one. Use
-- `uwsm stop` rather than the exit dispatcher: this is a uwsm-managed session,
-- and exit would remove Hyprland from under its clients mid-shutdown.
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || uwsm stop"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

-- Universal clipboard (Omarchy-style). send_shortcut targets the active window
-- when no `window` is given.
hl.bind(mainMod .. " + C", hl.dsp.send_shortcut({ mods = "CTRL",  key = "Insert" }), { description = "Universal copy" })
hl.bind(mainMod .. " + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), { description = "Universal paste" })
hl.bind(mainMod .. " + X", hl.dsp.send_shortcut({ mods = "CTRL",  key = "X" }),      { description = "Universal cut" })

hl.bind(mainMod .. " + SHIFT + V",    hl.dsp.exec_cmd("walker -m clipboard"), { description = "Clipboard history" })
hl.bind(mainMod .. " + CTRL + SPACE", hl.dsp.exec_cmd("walker -m symbols"),   { description = "Emoji picker" })
hl.bind("CTRL + SPACE", hl.dsp.exec_cmd(menu))

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + CTRL + L",  hl.dsp.exec_cmd("~/.config/hypr/scripts/hyprlock-dim.sh"))
hl.bind(mainMod .. " + CTRL + Q",  hl.dsp.exec_cmd("~/.config/hypr/scripts/hyprlock-dim.sh"))

-- Universal app shortcuts passed through to the focused window
-- hl.bind(mainMod .. " + K", hl.dsp.send_shortcut({ mods = "CTRL", key = "K" }))
hl.bind(mainMod .. " + F", hl.dsp.send_shortcut({ mods = "CTRL", key = "F" }))
hl.bind(mainMod .. " + D", hl.dsp.send_shortcut({ mods = "CTRL", key = "D" }))
hl.bind(mainMod .. " + P", hl.dsp.send_shortcut({ mods = "CTRL", key = "P" }))
hl.bind(mainMod .. " + W", hl.dsp.send_shortcut({ mods = "CTRL", key = "W" }))
hl.bind(mainMod .. " + T", hl.dsp.send_shortcut({ mods = "CTRL", key = "T" }))

-- Browser tab cycling. Supersedes an older ydotool-based implementation that
-- was already dead under the old .conf.
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.send_shortcut({ mods = "CTRL",       key = "Tab" }), { description = "Move right tab" })
hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.send_shortcut({ mods = "CTRL SHIFT", key = "Tab" }), { description = "Move left tab" })

-- Wallpaper picker (walker dmenu)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("bg-cycle"))

-- Screenshot region to clipboard
hl.bind(mainMod .. " + CTRL + SHIFT + 4", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))

--------------------
---- WORKSPACES ----
--------------------

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-------------------
---- MULTIMEDIA ---
-------------------

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
