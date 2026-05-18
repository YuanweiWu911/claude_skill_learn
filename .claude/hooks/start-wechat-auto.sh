#!/usr/bin/env bash

# start-wechat-auto.sh — Bash peer of start-wechat-auto.ps1

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
PID_PATH="$CLAUDE_DIR/wechat-auto.pid"
LAUNCHER_PATH="$SCRIPT_DIR/start-wechat-auto-runner.sh"

if [ ! -d "$CLAUDE_DIR" ]; then
    mkdir -p "$CLAUDE_DIR"
fi

# Simple pid-based locking (Linux doesn't have Windows Mutex)
if [ -f "$PID_PATH" ]; then
    PID=$(cat "$PID_PATH")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        if grep -q "start-wechat-auto-runner.sh" "/proc/$PID/cmdline" 2>/dev/null; then
            echo "{\"continue\":true,\"suppressOutput\":true}"
            exit 0
        fi
    fi
    rm -f "$PID_PATH"
fi

# Start runner in background with nohup
nohup bash "$LAUNCHER_PATH" "$PROJECT_ROOT" > /dev/null 2>&1 &
echo $! > "$PID_PATH"

echo "{\"continue\":true,\"suppressOutput\":true}"
