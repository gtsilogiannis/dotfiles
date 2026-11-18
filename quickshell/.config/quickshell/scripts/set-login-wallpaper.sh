#!/usr/bin/env bash
# Sets the login screen background, themed from the image (matugen --dry-run,
# so the desktop colors stay). The root part is sddm-set-background via pkexec.
#
#   set-login-wallpaper.sh <image>   use it (depth wallpapers without the effect)
#   set-login-wallpaper.sh --reset   back to the theme background
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
