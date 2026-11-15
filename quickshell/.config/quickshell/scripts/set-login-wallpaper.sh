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
# comes from its cutout, else from the half with less detail (edge energy).
#
# The root part is /usr/local/bin/sddm-set-background, run through pkexec
# (password prompt by hyprpolkitagent). It reads the image on stdin and takes
# the theme keys as arguments. On success the path is kept in
# ~/.local/state/desktop/login-wallpaper for the badge in the picker.
set -euo pipefail

helper=/usr/local/bin/sddm-set-background
state="$HOME/.local/state/desktop"
record="$state/login-wallpaper"
depth="$HOME/.local/share/depth"

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

# Prints "left" or "right": the side of the form.
form_side() {
    local meta stem center left right
    stem=$(basename "${file%.*}")
    meta="$depth/$stem.depth.json"
    if [[ "$file" == */wallpapers/depth/* && -s "$meta" ]]; then
        center=$(jq -r '(.cutout.x + .cutout.width / 2) / .width' "$meta")
    else
        read -r left right < <(magick "$file" -resize 192x108! -colorspace gray -edge 1 \
            -crop 2x1@ +repage -format '%[fx:mean] ' info: 2>/dev/null) || true
        center=$(awk -v l="${left:-0}" -v r="${right:-0}" 'BEGIN { print (l > r) ? 0.25 : 0.75 }')
    fi
    awk -v c="$center" 'BEGIN { print (c > 0.5) ? "left" : "right" }'
}

json=$(matugen image "$file" -t scheme-vibrant -m dark --source-color-index 0 --dry-run --json hex)
color() {
    jq -er --arg k "$1" '.colors[$k].default.color // .colors[$k].dark.color' <<< "$json"
}

# theme key  matugen color
map=(
    HeaderTextColor primary
    DateTextColor primary
    TimeTextColor on_surface
    FormBackgroundColor surface
    BackgroundColor surface
    DimBackgroundColor surface
    LoginFieldBackgroundColor surface_container_high
    PasswordFieldBackgroundColor surface_container_high
    LoginFieldTextColor on_surface
    PasswordFieldTextColor on_surface
    UserIconColor primary
    PasswordIconColor primary
    PlaceholderTextColor on_surface_variant
    WarningColor error
    LoginButtonTextColor on_primary
    LoginButtonBackgroundColor primary
    SystemButtonsIconsColor on_surface
    SessionButtonTextColor on_surface
    VirtualKeyboardButtonTextColor on_surface
    DropdownTextColor on_surface
    DropdownSelectedBackgroundColor secondary_container
    DropdownBackgroundColor surface_container
    HighlightTextColor on_primary
    HighlightBackgroundColor primary
    HighlightBorderColor primary
    HoverUserIconColor tertiary
    HoverPasswordIconColor tertiary
    HoverSystemButtonsIconsColor tertiary
    HoverSessionButtonTextColor tertiary
    HoverVirtualKeyboardButtonTextColor tertiary
)

args=(Font="IBM Plex Sans" FormPosition="$(form_side)" PartialBlur=true HaveFormBackground=false Blur=1.0 BlurMax=32 RoundCorners=24)
for ((i = 0; i < ${#map[@]}; i += 2)); do
    args+=("${map[i]}=$(color "${map[i + 1]}")")
done

pkexec "$helper" "${args[@]}" < "$file"
printf '%s\n' "$file" > "$record"
