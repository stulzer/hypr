-- Environment variables
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("GDK_SCALE", "2")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_THEME", "Adwaita:dark")

-- Autostart -- https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("walker --gapplication-service")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("bg-random")

    -- Required by scripts/hyprlock-dim.sh: without the gammarelay daemon,
    -- eDP-1 lock dimming silently no-ops. See docs/hyprlock-adaptive-dimming.md.
    hl.exec_cmd("WAYLAND_DISPLAY=$WAYLAND_DISPLAY wl-gammarelay-rs")
end)
