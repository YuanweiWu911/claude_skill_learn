#!/usr/bin/env bash

# wechat-approve.sh — Bash peer of wechat-approve.ps1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CLI_PATH="$PROJECT_ROOT/.claude/hooks/wechat-approve-cli.ts"

COMMAND=${1:-"list"}
ID=$2

if [ -n "$ID" ]; then
    bun run --cwd "$PROJECT_ROOT" "$CLI_PATH" "$COMMAND" "$ID"
else
    bun run --cwd "$PROJECT_ROOT" "$CLI_PATH" "$COMMAND"
fi
