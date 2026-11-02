#!/usr/bin/env bash
# Applies a wallpaper chosen in the wallpaper picker: awww on every output,
# a copy for hyprlock and the next login, and new colors from matugen for
# every themed app (Hyprland borders, kitty, GTK, Quickshell).
set -euo pipefail

wall="$1"
[[ -f "$wall" ]] || { echo "not a file: $wall" >&2; exit 1; }

if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon --format xrgb &
    sleep 1
fi

awww img "$wall" --transition-type wipe --transition-angle 30 --transition-step 90 --transition-fps 144

# Read at login (autostart) and by hyprlock; the .path file marks the current one in the picker.
mkdir -p "$HOME/.cache"
cp -f "$wall" "$HOME/.cache/current_wallpaper.png"
printf '%s\n' "$wall" > "$HOME/.cache/current_wallpaper.path"

# --source-color-index 0: without it matugen asks interactively which color to use.
matugen image "$wall" -t scheme-tonal-spot --source-color-index 0
