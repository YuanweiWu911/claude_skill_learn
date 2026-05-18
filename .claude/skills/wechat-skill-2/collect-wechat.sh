#!/usr/bin/env bash

# collect-wechat.sh — Bash peer of collect-wechat.ps1
# Usage: ./collect-wechat.sh [--start] [--stop] [--all] [--limit N]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/../../hooks" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PID_PATH="$PROJECT_ROOT/.claude/wechat-auto.pid"

START_SCRIPT="$HOOKS_DIR/start-wechat-auto.sh"
STOP_SCRIPT="$HOOKS_DIR/stop-wechat-auto.sh"

function is_watcher_running() {
    if [ -f "$PID_PATH" ]; then
        PID=$(cat "$PID_PATH")
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            # Verify it's actually our watcher by checking cmdline
            if grep -q "wechat-auto-reply.ts" "/proc/$PID/cmdline" 2>/dev/null; then
                return 0
            fi
        fi
    fi
    # Fallback: scan proc
    if pgrep -f "wechat-auto-reply.ts" > /dev/null; then
        return 0
    fi
    return 1
}

ARGS=("$@")
START_REQUESTED=false
STOP_REQUESTED=false

for arg in "$@"; do
    if [ "$arg" == "--start" ]; then START_REQUESTED=true; fi
    if [ "$arg" == "--stop" ]; then STOP_REQUESTED=true; fi
done

if $START_REQUESTED; then
    if is_watcher_running; then
        echo "watcher 已经在运行。"
        exit 0
    fi
    bash "$START_SCRIPT"
    echo "已启动 watcher。"
    exit 0
fi

if $STOP_REQUESTED; then
    if ! is_watcher_running; then
        echo "watcher 未运行，无需停止。"
        exit 0
    fi
    bash "$STOP_SCRIPT"
    echo "已停止 watcher。"
    exit 0
fi

# Default: status
if is_watcher_running; then
    echo "watcher 运行中。"
else
    echo "watcher 未运行。"
fi
