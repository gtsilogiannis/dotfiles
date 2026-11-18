#!/usr/bin/env bash
# Locks the session (SUPER + L, power menu, hypridle). Its own qs instance, so
# the bar can restart or crash without touching it. qs inherits the flock on fd 9.
set -euo pipefail

run="${XDG_RUNTIME_DIR:-/tmp}"
exec 9> "$run/qs-lock.lock"
flock -n 9 || exit 0
exec qs -p "$HOME/.config/quickshell/lock/shell.qml" > "$run/qs-lock.log" 2>&1
