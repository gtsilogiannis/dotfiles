#!/bin/sh
# SUPER + Q. Closes the focused window; for apps that keep running in the
# background when their window closes (Claude Desktop), quits the app instead.
set -u

class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

case "$class" in
    com.anthropic.Claude)
        # SIGTERM to the main process: Electron runs its quit handlers and exits.
        # Those handlers finish in about a second, but the app then waits up to 75 s
        # for a telemetry flush, and a new launch during that time opens no window.
        # After 15 s, whatever is left is killed.
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
