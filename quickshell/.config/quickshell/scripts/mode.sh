#!/usr/bin/env bash
# Switches the desktop between browsing and focus modes.
#
#   mode.sh browsing | focus | toggle   switch (focus turns Do Not Disturb on)
#   mode.sh opaque on | off | toggle    browsing only: opaque instead of glass windows
#   mode.sh init                        at login: browsing with glass windows
#   mode.sh get                         print the current mode
#
# State lives in ~/.local/state/desktop/:
#   mode                  "browsing" or "focus", read by Hyprland and Quickshell
#   opaque                "on" or "off", read by Hyprland and Quickshell
#   wallpaper-<mode>      last wallpaper used in each mode
#   dnd-before-focus      Do Not Disturb state to restore when focus ends
set -euo pipefail

state="$HOME/.local/state/desktop"
scripts="$(dirname "$(readlink -f "$0")")"
mkdir -p "$state"

current_mode() {
    local m
    m=$(cat "$state/mode" 2>/dev/null || true)
    [[ "$m" == focus ]] && echo focus || echo browsing
}

# Quickshell may not be running yet (login) or may be restarting; never fail on it.
qs_dnd_get() { qs ipc call notifications getDnd 2>/dev/null || echo false; }
qs_dnd_set() { qs ipc call notifications setDnd "$1" >/dev/null 2>&1 || true; }

switch_to() {
    local target="$1" from wall
    from=$(current_mode)

    # Remember the wallpaper of the mode being left.
    wall=$(cat "$HOME/.cache/current_wallpaper.path" 2>/dev/null || true)
    [[ -n "$wall" && -f "$wall" ]] && printf '%s\n' "$wall" > "$state/wallpaper-$from"

    # The target mode's own wallpaper, else keep the current one.
    local next
    next=$(cat "$state/wallpaper-$target" 2>/dev/null || true)
    [[ -n "$next" && -f "$next" ]] || next="$wall"
    [[ -n "$next" && -f "$next" ]] || next="$HOME/.cache/current_wallpaper.png"

    # Do Not Disturb: on in focus, back to what it was before when focus ends.
    if [[ "$target" == focus && "$from" != focus ]]; then
        qs_dnd_get > "$state/dnd-before-focus"
        qs_dnd_set true
    elif [[ "$target" == browsing && "$from" == focus ]]; then
        qs_dnd_set "$(cat "$state/dnd-before-focus" 2>/dev/null || echo false)"
        rm -f "$state/dnd-before-focus"
    fi

    # Written before the wallpaper so set-wallpaper.sh picks the target's color scheme.
    printf '%s\n' "$target" > "$state/mode"
    # A failed wallpaper or color step must not leave Hyprland in the old mode.
    "$scripts/set-wallpaper.sh" "$next" || echo "mode.sh: set-wallpaper.sh failed, colors unchanged" >&2

    # Hyprland reads the mode file while loading its config (borders, opacity, animations).
    hyprctl reload >/dev/null
}

# Windows in focus are always opaque, so the switch only applies in browsing.
set_opaque() {
    local value="$1"
    if [[ "$value" == toggle ]]; then
        if [[ "$(cat "$state/opaque" 2>/dev/null || true)" == on ]]; then value=off; else value=on; fi
    fi
    [[ "$(current_mode)" == focus ]] && return 0
    printf '%s\n' "$value" > "$state/opaque"
    hyprctl reload >/dev/null
}

# One switch at a time: a second key press while a switch runs is dropped.
exec 9> "$state/.lock"
flock -n 9 || exit 0

case "${1:-}" in
    browsing|focus)
        [[ "$(current_mode)" == "$1" ]] || switch_to "$1"
        ;;
    toggle)
        if [[ "$(current_mode)" == focus ]]; then switch_to browsing; else switch_to focus; fi
        ;;
    init)
        # Quickshell starts with Do Not Disturb off, so there is nothing to restore.
        rm -f "$state/dnd-before-focus"
        # Every session starts with glass windows. Hyprland has already read the
        # file of the previous session, so it reloads if that one ended opaque.
        was_opaque=$(cat "$state/opaque" 2>/dev/null || true)
        printf '%s\n' off > "$state/opaque"
        if [[ "$(current_mode)" == focus ]]; then
            switch_to browsing
        else
            printf '%s\n' browsing > "$state/mode"
            if [[ "$was_opaque" == on ]]; then hyprctl reload >/dev/null; fi
            # awww only shows the still of a video wallpaper.
            "$scripts/set-wallpaper.sh" --resume || true
        fi
        ;;
    opaque)
        case "${2:-toggle}" in
            on|off|toggle) set_opaque "${2:-toggle}" ;;
            *) echo "usage: ${0##*/} opaque on|off|toggle" >&2; exit 2 ;;
        esac
        ;;
    get)
        current_mode
        ;;
    *)
        echo "usage: ${0##*/} browsing|focus|toggle|opaque [on|off|toggle]|init|get" >&2
        exit 2
        ;;
esac
