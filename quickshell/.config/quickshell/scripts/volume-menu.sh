#!/bin/sh
# Volume pill: toggles pavucontrol; its window rule is in hyprland.lua
if pgrep -x pavucontrol >/dev/null; then
    pkill -x pavucontrol
else
    pavucontrol >/dev/null 2>&1 &
fi
