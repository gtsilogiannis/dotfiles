#!/usr/bin/env bash
# Applies a wallpaper chosen in the wallpaper picker or by mode.sh: awww on
# every output, a copy for hyprlock and the next login, and new colors from
# matugen for every themed app (Hyprland borders, kitty, GTK, Quickshell).
set -euo pipefail

wall="$1"
[[ -f "$wall" ]] || { echo "not a file: $wall" >&2; exit 1; }

# The color scheme follows the desktop mode (mode.sh): vibrant in browsing,
# monochrome in focus. Both stay dark for now.
state="$HOME/.local/state/desktop"
mode=$(cat "$state/mode" 2>/dev/null || echo browsing)
case "$mode" in
    focus) scheme="scheme-monochrome" ;;
    *)     scheme="scheme-vibrant" ;;
esac

# A mode switch that keeps the wallpaper only changes the colors. The cached
# copy itself (mode.sh's fallback when no source path is known) is never
# recorded as a source, or a later wallpaper change would overwrite it.
cache="$HOME/.cache/current_wallpaper.png"
current=$(cat "$HOME/.cache/current_wallpaper.path" 2>/dev/null || true)
is_cache=0
[[ "$wall" -ef "$cache" ]] && is_cache=1
if [[ $is_cache -eq 0 && "$wall" != "$current" ]]; then
    if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon --format xrgb &
        sleep 1
    fi

    awww img "$wall" --transition-type wipe --transition-angle 30 --transition-step 90 --transition-fps 144

    # Read at login (autostart) and by hyprlock; the .path file marks the current one in the picker.
    mkdir -p "$HOME/.cache"
    cp -f "$wall" "$cache"
    printf '%s\n' "$wall" > "$HOME/.cache/current_wallpaper.path"
fi

# Each mode remembers its own wallpaper.
if [[ $is_cache -eq 0 ]]; then
    mkdir -p "$state"
    printf '%s\n' "$wall" > "$state/wallpaper-$mode"
fi

# --source-color-index 0: without it matugen asks interactively which color to use.
matugen image "$wall" -t "$scheme" -m dark --source-color-index 0
