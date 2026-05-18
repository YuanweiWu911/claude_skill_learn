#!/usr/bin/env bash

# stop-wechat-auto.sh — Bash peer of stop-wechat-auto.ps1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PID_PATH="$PROJECT_ROOT/.claude/wechat-auto.pid"

function stop_by_pattern() {
    local pattern=$1
    # Find PIDs matching pattern and project root in cmdline
    # Use ps to get full cmdline for better matching
    pids=$(ps -eo pid,cmd | grep "$pattern" | grep "$PROJECT_ROOT" | grep -v grep | awk '{print $1}')
    for pid in $pids; do
        # Use SIGKILL to ensure it stops immediately
        kill -9 "$pid" 2>/dev/null || true
    done
}

if [ -f "$PID_PATH" ]; then
    PID=$(cat "$PID_PATH")
    if [ -n "$PID" ]; then
        # Check if it's the runner script
        if ps -p "$PID" -o cmd= | grep -q "start-wechat-auto-runner.sh"; then
             kill -9 "$PID" 2>/dev/null || true
        fi
    fi
    rm -f "$PID_PATH"
fi

# Cleanup any orphaned processes by scanning the process table
stop_by_pattern "wechat-auto-reply.ts"
stop_by_pattern "start-wechat-auto-runner.sh"

echo "WeChat auto-reply watcher stopped."
