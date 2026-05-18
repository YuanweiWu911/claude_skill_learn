#!/usr/bin/env bash

# stop-wechat-auto.sh — Bash peer of stop-wechat-auto.ps1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PID_PATH="$PROJECT_ROOT/.claude/wechat-auto.pid"

function stop_by_pattern() {
    local pattern=$1
    # Find PIDs matching pattern and project root in cmdline
    pids=$(pgrep -f "$pattern" || true)
    for pid in $pids; do
        if grep -q "$PROJECT_ROOT" "/proc/$pid/cmdline" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    done
}

if [ -f "$PID_PATH" ]; then
    PID=$(cat "$PID_PATH")
    if [ -n "$PID" ]; then
        kill -9 "$PID" 2>/dev/null || true
    fi
    rm -f "$PID_PATH"
fi

# Cleanup any orphaned processes
stop_by_pattern "wechat-auto-reply.ts"
stop_by_pattern "start-wechat-auto-runner.sh"

echo "WeChat auto-reply watcher stopped."
