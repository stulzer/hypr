-- Monitors -- https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
    output   = "DP-2",
    mode     = "3840x2160@60",
    position = "1920x0",
    scale    = 2,
})

-- eDP-1 state is managed by waybar's monitor-toggle.sh, which overwrites
-- monitors_edp1.lua wholesale and applies the change with `hyprctl eval`.
-- Keep it in its own file so the toggle can never clobber the config above.
require("monitors_edp1")
