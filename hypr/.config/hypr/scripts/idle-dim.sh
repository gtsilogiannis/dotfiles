#!/bin/sh
# Called by hypridle. "dim" saves the panel brightness and lowers it to 30%
# when it is brighter than that; "restore" brings the saved value back.
set -eu

case "${1:-}" in
    dim)
        brightnessctl -q -s set +0
        now=$(brightnessctl -m | cut -d, -f4 | tr -d %)
        if [ "$now" -gt 30 ]; then
            brightnessctl -q set 30%
        fi
        ;;
    restore)
        brightnessctl -q -r
        ;;
    *)
        echo "usage: idle-dim.sh dim|restore" >&2
        exit 2
        ;;
esac
