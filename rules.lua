-- Windows and workspaces
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- Rules are evaluated top to bottom, so the order below matters.

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Fixes weird background noise at waybar
hl.layer_rule({
    name  = "waybar-no-blur",
    match = { namespace = "waybar" },

    blur = false,
})

hl.window_rule({
    name  = "pip-float",
    match = { title = "(?i)picture.in.picture" },

    float = true,
    pin   = true,
})

-- Block formatting configuration for Ghost Recon Breakpoint
hl.window_rule({
    name  = "shattered-breakpoint",
    match = { class = "^(shattered.exe)$" },

    float       = true,
    no_max_size = true,
    fullscreen  = true,
    no_blur     = true,
    immediate   = true,
})
