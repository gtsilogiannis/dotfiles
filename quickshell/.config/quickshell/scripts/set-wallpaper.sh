#!/usr/bin/env bash
# Applies a wallpaper chosen in the wallpaper picker or by mode.sh, and takes
# new colors from it with matugen for every themed app (Hyprland borders,
# kitty, GTK, Quickshell).
#
#   set-wallpaper.sh <image|video>   apply it
#   set-wallpaper.sh --resume        at login: play the current wallpaper
#                                    again if it is a video
#
# An image is shown by awww. A video is played by mpvpaper on every output,
# above a still of its first frame: awww shows that still, hyprlock uses it
# and the next login starts with it. The colors of a video come from a frame
# at 10% of its length. Focus mode shows the still only.
set -euo pipefail

state="$HOME/.local/state/desktop"
cache="$HOME/.cache/current_wallpaper.png"
pathfile="$HOME/.cache/current_wallpaper.path"
frames="$HOME/.cache/wallpaper-frames"

is_video() {
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.mov) return 0 ;;
        *) return 1 ;;
    esac
}

stop_video() {
    pkill -x mpvpaper 2>/dev/null || true
    pkill -x mpvpaper-holder 2>/dev/null || true
}

# mpv decodes on the integrated GPU, the one that also draws the wallpaper
# (VA-API, no copy), and falls back to software decoding if that fails.
# Hyprland exports LIBVA_DRIVER_NAME=nvidia for everything else. Quickshell
# (VideoWallpaper.qml) pauses the video through the socket while a window has
# focus, and is told here that a new mpv is listening. mode.sh holds its lock
# on descriptor 9, which a daemon must not inherit.
start_video() {
    stop_video
    LIBVA_DRIVER_NAME=iHD mpvpaper -f \
        -o "no-audio loop hwdec=vaapi panscan=1.0 input-ipc-server=${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.sock" \
        ALL "$1" >/dev/null 2>&1 9>&-
    ( sleep 1; qs ipc call wallpaper sync ) >/dev/null 2>&1 9>&- &
}

# video_frame <video> first|colors: path of a cached still that covers 1920x1080.
video_frame() {
    local video="$1" which="$2" at=0 out dur
    out="$frames/$(basename "${video%.*}")-$(stat -c %Y "$video")-$which.png"
    if [[ ! -s "$out" ]]; then
        mkdir -p "$frames"
        if [[ "$which" == colors ]]; then
            dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video" 2>/dev/null || true)
            at=$(awk -v d="${dur:-0}" 'BEGIN { printf "%.2f", d * 0.1 }')
        fi
        ffmpeg -v error -y -ss "$at" -i "$video" -frames:v 1 \
            -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" \
            "${out%.png}.part.png" </dev/null
        mv -f "${out%.png}.part.png" "$out"
    fi
    printf '%s\n' "$out"
}

# "x,y" of the cursor inside its own output, measured from the top left.
transition_pos() {
    local pos mons
    pos=$(hyprctl cursorpos 2>/dev/null) || return 1
    mons=$(hyprctl -j monitors 2>/dev/null) || return 1
    jq -er --arg pos "$pos" '
        ($pos | split(",") | map(gsub(" "; "") | tonumber)) as [$x, $y]
        | map(select($x >= .x and $x < .x + (.width / .scale)
                 and $y >= .y and $y < .y + (.height / .scale)))
        | first | "\($x - .x | floor),\($y - .y | floor)"' <<< "$mons" 2>/dev/null
}

# The new image grows out of the cursor, or out of the center without one.
show_image() {
    local pos
    if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon --format xrgb 9>&- &
        sleep 1
    fi
    if pos=$(transition_pos); then
        awww img "$1" --transition-type grow --transition-pos "$pos" --invert-y \
            --transition-duration 1.2 --transition-fps 144
    else
        awww img "$1" --transition-type grow --transition-duration 1.2 --transition-fps 144
    fi
}

if [[ "${1:-}" == --resume ]]; then
    wall=$(cat "$pathfile" 2>/dev/null || true)
    mode=$(cat "$state/mode" 2>/dev/null || echo browsing)
    if [[ -n "$wall" && -f "$wall" && "$mode" != focus ]] && is_video "$wall" \
        && ! pgrep -x mpvpaper >/dev/null; then
        start_video "$wall"
    fi
    exit 0
fi

wall="${1:-}"
[[ -f "$wall" ]] || { echo "not a file: $wall" >&2; exit 1; }

# The color scheme follows the desktop mode (mode.sh): vibrant in browsing,
# monochrome in focus. Both stay dark for now.
mode=$(cat "$state/mode" 2>/dev/null || echo browsing)
case "$mode" in
    focus) scheme="scheme-monochrome" ;;
    *)     scheme="scheme-vibrant" ;;
esac

# What awww shows, what matugen reads and what mpvpaper plays.
still="$wall"
colors="$wall"
video=""
if is_video "$wall"; then
    still=$(video_frame "$wall" first)
    colors=$(video_frame "$wall" colors)
    [[ "$mode" == focus ]] || video="$wall"
fi

# A mode switch that keeps the wallpaper only changes the colors. The cached
# copy itself (mode.sh's fallback when no source path is known) is never
# recorded as a source, or a later wallpaper change would overwrite it.
current=$(cat "$pathfile" 2>/dev/null || true)
is_cache=0
[[ "$wall" -ef "$cache" ]] && is_cache=1
if [[ $is_cache -eq 0 && "$wall" != "$current" ]]; then
    stop_video
    show_image "$still"

    # Read at login (autostart) and by hyprlock; the .path file marks the current one in the picker.
    mkdir -p "$HOME/.cache"
    cp -f "$still" "$cache"
    printf '%s\n' "$wall" > "$pathfile"

    # The video starts once awww has finished growing its first frame, unless
    # another wallpaper or focus mode has taken over in the meantime.
    if [[ -n "$video" ]]; then
        (
            sleep 1.3
            [[ "$(cat "$pathfile" 2>/dev/null || true)" == "$video" ]] || exit 0
            [[ "$(cat "$state/mode" 2>/dev/null || true)" == focus ]] && exit 0
            start_video "$video"
        ) >/dev/null 2>&1 9>&- &
    fi
elif [[ -n "$video" ]]; then
    # Back from focus with the same video: its still is already on screen.
    pgrep -x mpvpaper >/dev/null || start_video "$video"
else
    stop_video
fi

# Each mode remembers its own wallpaper.
if [[ $is_cache -eq 0 ]]; then
    mkdir -p "$state"
    printf '%s\n' "$wall" > "$state/wallpaper-$mode"
fi

# --source-color-index 0: without it matugen asks interactively which color to use.
matugen image "$colors" -t "$scheme" -m dark --source-color-index 0
