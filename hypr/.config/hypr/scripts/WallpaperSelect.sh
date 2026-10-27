#!/usr/bin/env bash

WALL_DIR="$HOME/Pictures/wallpapers"

# Start awww-daemon if it is not already running
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon --format xrgb &
    sleep 1
fi

# List all wallpapers relative to WALL_DIR for a clean Rofi menu
CHOICE=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | sed "s|$WALL_DIR/||" | sort | rofi -dmenu -i -p "󰸉 Wallpapers" -theme-str 'window {width: 500px;} listview {lines: 10;}')

# Exit quietly if Rofi is closed with ESC
if [ -z "$CHOICE" ]; then
    exit 0
fi

# Build the absolute path of the selection
SELECTED_WALL="$WALL_DIR/$CHOICE"

# Apply the wallpaper to the desktop
awww img "$SELECTED_WALL" --transition-type wipe --transition-angle 30 --transition-step 90 --transition-fps 144

# Save a copy for Hyprlock
mkdir -p "$HOME/.cache"
cp -f "$SELECTED_WALL" "$HOME/.cache/current_wallpaper.png"

