#!/usr/bin/env bash
# Makes an image the background of the login screen (SDDM), from the
# wallpaper picker (Shift + Enter in the Static and Depth tabs) or by hand:
#
#   set-login-wallpaper.sh <image>   use it (a depth wallpaper without its effect)
#   set-login-wallpaper.sh --reset   back to the background of the theme
#
# The theme follows the image: colors from matugen (scheme-vibrant, dark, as
# in browsing mode; --dry-run, so the desktop colors stay), IBM Plex Sans, and
# the form on the side away from the subject. For a depth wallpaper the side
# comes from its cutout, else from the half with less detail (form-side.sh).
#
# The root part is /usr/local/bin/sddm-set-background, run through pkexec
# (password prompt by hyprpolkitagent). It reads the image on stdin and takes
# the theme keys as arguments. On success the path is kept in
# ~/.local/state/desktop/login-wallpaper for the badge in the picker.
set -euo pipefail

helper=/usr/local/bin/sddm-set-background
state="$HOME/.local/state/desktop"
record="$state/login-wallpaper"
scripts=$(dirname -- "$0")

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

json=$(matugen image "$file" -t scheme-vibrant -m dark --source-color-index 0 --dry-run --json hex)
color() {
    jq -er --arg k "$1" '.colors[$k].default.color // .colors[$k].dark.color' <<< "$json"
}

# theme key  matugen color
map=(
    PrimaryColor primary
    OnPrimaryColor on_primary
    SurfaceColor surface
    OnSurfaceColor on_surface
    OnSurfaceVariantColor on_surface_variant
    FieldColor surface_container_high
    ErrorColor error
    AccentColor tertiary
)

args=(Font="IBM Plex Sans" FormPosition="$("$scripts/form-side.sh" "$file")" Blur=1.0 BlurMax=32 RoundCorners=24)
for ((i = 0; i < ${#map[@]}; i += 2)); do
    args+=("${map[i]}=$(color "${map[i + 1]}")")
done

pkexec "$helper" "${args[@]}" < "$file"
printf '%s\n' "$file" > "$record"
