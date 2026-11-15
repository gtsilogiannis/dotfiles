#!/usr/bin/env bash
# Locks the session with the Quickshell lock screen (lock/shell.qml), from
# SUPER + L, the power menu and hypridle (lock_cmd, also before sleep).
#
# The lock runs in its own qs instance, apart from the bar: restarting or a
# crash of the shell does not touch it, and nothing of it stays in memory
# once unlocked. flock keeps a second call from starting a second lock; qs
# inherits descriptor 9, so the lock is held until it exits.
set -euo pipefail

run="${XDG_RUNTIME_DIR:-/tmp}"
exec 9> "$run/qs-lock.lock"
flock -n 9 || exit 0
exec qs -p "$HOME/.config/quickshell/lock/shell.qml" > "$run/qs-lock.log" 2>&1
