#!/usr/bin/env bash
# Makes an image the background of the login screen (SDDM), from the
# wallpaper picker (Shift + Enter in the Static and Depth tabs) or by hand:
#
#   set-login-wallpaper.sh <image>   use it (a depth wallpaper without its effect)
#   set-login-wallpaper.sh --reset   back to the background of the theme
#
# The root part is /usr/local/bin/sddm-set-background, run through pkexec
# (password prompt by hyprpolkitagent). It reads the image on stdin. On success
# the path is kept in ~/.local/state/desktop/login-wallpaper for the badge in
# the picker.
set -euo pipefail

helper=/usr/local/bin/sddm-set-background
state="$HOME/.local/state/desktop"
record="$state/login-wallpaper"

[[ -x "$helper" ]] || { printf '%s is not installed\n' "$helper" >&2; exit 1; }
mkdir -p "$state"

if [[ "${1:-}" == --reset ]]; then
    pkexec "$helper" --reset
    : > "$record"
    exit 0
fi

file="${1:?usage: set-login-wallpaper.sh <image> | --reset}"
[[ -f "$file" && -r "$file" ]] || { printf 'not a readable file: %s\n' "$file" >&2; exit 1; }
file=$(realpath -- "$file")

pkexec "$helper" < "$file"
printf '%s\n' "$file" > "$record"
