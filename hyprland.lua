-- Hyprland configuration.
-- Refer to the wiki for more information: https://wiki.hypr.land/Configuring/Start/
--
-- Split into modules. Each require() is its own error scope in Hyprland's Lua
-- runtime, so a mistake in one file does not stop the others from loading.
--
-- Order matters: window rules are evaluated top to bottom, and when two binds
-- claim the same key combo the last one defined wins.

require("monitors")
require("env")
require("look")
require("input")
require("binds")
require("rules")
