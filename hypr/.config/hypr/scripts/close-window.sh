#!/bin/sh
# SUPER + Q: close the focused window, or quit apps that keep running in the
# background once their window is closed.
set -u

class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

case "$class" in
    com.anthropic.Claude)
        # Electron quits on SIGTERM but can wait up to 75 s on a telemetry flush,
        # and a new launch opens no window until then: kill what is left after 15 s.
        pkill -x claude-desktop
        (
            i=0
            while [ "$i" -lt 15 ] && pgrep -x claude-desktop >/dev/null; do
                sleep 1
                i=$((i + 1))
            done
            pkill -KILL -x claude-desktop
        ) >/dev/null 2>&1 &
        ;;
    *)
        hyprctl dispatch 'hl.dsp.window.close()' >/dev/null
        ;;
esac
