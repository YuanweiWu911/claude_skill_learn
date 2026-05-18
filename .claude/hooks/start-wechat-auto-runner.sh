#!/usr/bin/env bash

# start-wechat-auto-runner.sh — Bash peer of start-wechat-auto-runner.ps1

PROJECT_ROOT=$1
if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

cd "$PROJECT_ROOT"

LOG_PATH="$PROJECT_ROOT/.claude/wechat-auto.log"
PID_PATH="$PROJECT_ROOT/.claude/wechat-auto.pid"
SCRIPT_PATH="$PROJECT_ROOT/.claude/hooks/wechat-auto-reply.ts"

function log() {
    echo "[$(date -u +'%Y-%m-%dT%H:%M:%S.%3NZ')] Runner: $1" >> "$LOG_PATH"
}

BUN_EXE=$(which bun || echo "bun")
CURRENT_PID=$$

# Ensure we are the registered PID
echo "$CURRENT_PID" > "$PID_PATH"
log "started pid=$CURRENT_PID bun=$BUN_EXE"

BACKOFF=2
MAX_BACKOFF=120

while true; do
    if [ ! -f "$PID_PATH" ]; then
        log "PID file removed, exiting"
        break
    fi

    ACTIVE_PID=$(cat "$PID_PATH")
    if [ "$ACTIVE_PID" != "$CURRENT_PID" ]; then
        log "PID file reassigned to $ACTIVE_PID, exiting"
        break
    fi

    # Run the watcher
    EXIT_CODE=0
    $BUN_EXE run "$SCRIPT_PATH" --project-root "$PROJECT_ROOT" >> "$LOG_PATH" 2>&1 || EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 1 ] || [ $EXIT_CODE -eq 2 ]; then
        log "watcher exited normally (code $EXIT_CODE), stopping"
        break
    fi

    log "watcher crashed (code $EXIT_CODE), restart in ${BACKOFF}s"
    sleep $BACKOFF
    BACKOFF=$((BACKOFF * 2))
    if [ $BACKOFF -gt $MAX_BACKOFF ]; then BACKOFF=$MAX_BACKOFF; fi
done
