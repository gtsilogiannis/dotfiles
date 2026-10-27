#!/usr/bin/env bash

options="Lock\nSuspend\nLogout\nReboot\nShutdown"

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power" -theme-str 'window {width: 260px;} listview {lines: 5;}')

case "$chosen" in
    "Lock")
        hyprlock
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Logout")
        hyprctl dispatch 'hl.dsp.exit()'
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
esac
