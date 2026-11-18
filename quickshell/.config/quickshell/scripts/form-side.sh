#!/usr/bin/env bash
# Prints the side of an image away from its subject (left or right), where the
# login and lock screens put their form.
#
#   form-side.sh <image>
#
# Depth wallpapers use their cutout; others the half with less edge energy.
set -euo pipefail

file="${1:?usage: form-side.sh <image>}"
depth="$HOME/.local/share/depth"
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
