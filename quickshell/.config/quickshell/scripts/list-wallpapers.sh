#!/usr/bin/env bash
# Lists the wallpapers for the picker. First line: "current<TAB>path" of the
# wallpaper in use, then one line per file: "type<TAB>path<TAB>thumbnail".
#
# The type is the folder under ~/Pictures/wallpapers the file is in (static,
# depth, video or focus); anything else counts as static. An image is its own
# thumbnail; a video gets a small cached still taken at 10% of its length.
set -euo pipefail

dir="${1:-$HOME/Pictures/wallpapers}"
frames="$HOME/.cache/wallpaper-frames"

printf 'current\t%s\n' "$(cat "$HOME/.cache/current_wallpaper.path" 2>/dev/null || true)"

video_thumb() {
    local video="$1" out dur at
    out="$frames/$(basename "${video%.*}")-$(stat -c %Y "$video")-thumb.jpg"
    if [[ ! -s "$out" ]]; then
        mkdir -p "$frames"
        dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video" 2>/dev/null || true)
        at=$(awk -v d="${dur:-0}" 'BEGIN { printf "%.2f", d * 0.1 }')
        ffmpeg -v error -y -ss "$at" -i "$video" -frames:v 1 -q:v 4 \
            -vf "scale=480:270:force_original_aspect_ratio=increase,crop=480:270" \
            "${out%.jpg}.part.jpg" </dev/null 2>/dev/null || return 1
        mv -f "${out%.jpg}.part.jpg" "$out"
    fi
    printf '%s\n' "$out"
}

find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \
    -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) | sort |
while IFS= read -r file; do
    rel="${file#"$dir"/}"
    type="static"
    case "$rel" in
        depth/*) type="depth" ;;
        video/*) type="video" ;;
        focus/*) type="focus" ;;
    esac
    thumb="$file"
    case "${file,,}" in
        *.mp4|*.webm|*.mkv|*.mov) thumb=$(video_thumb "$file" || true) ;;
    esac
    printf '%s\t%s\t%s\n' "$type" "$file" "$thumb"
done
