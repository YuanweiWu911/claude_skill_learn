# Design Spec: Linux (Ubuntu) Port for wechat-skill

**Date:** 2026-05-18
**Branch:** `linux`
**Status:** Draft

## 1. Goal

Make `wechat-skill-2` work on Ubuntu (and potentially other Linux distributions) while preserving full Windows compatibility. The existing codebase is entirely Windows-specific (PowerShell scripts, `tasklist`/`taskkill`/`where.exe` commands, C# system tray).

## 2. Approach: Platform Abstraction Layer + Bash Peer Scripts (Option A)

Introduce a thin `platform.ts` module in TypeScript to encapsulate all OS differences, and create Bash `.sh` peer scripts alongside existing PowerShell `.ps1` scripts. SKILL.md gains dual-syntax command documentation.

## 3. Architecture

```
SKILL.md  (dual-syntax: PowerShell / Bash commands)
    │
    ├─────────────────────────┬────────────────────────────┐
    ▼                         ▼                            ▼
*.ps1 (Windows)          *.sh (Linux)              TypeScript (shared)
                                                          │
                                                    platform.ts ← NEW
                                                    (OS abstraction)
                                                    ┌──────┴──────┐
                                                    ▼             ▼
                                               Win32 APIs    Linux APIs
```

## 4. New/Modified Files

### 4.1 NEW: `platform.ts` (project root)

OS abstraction module. Detect platform once at module load; all functions branch internally.

| Function | Windows impl | Linux impl |
|----------|-------------|------------|
| `isWindows()` | `process.platform === "win32"` | — |
| `isLinux()` | — | `process.platform === "linux"` |
| `isProcessAlive(pid)` | `tasklist /FI "PID eq N"` | `fs.existsSync("/proc/N")` + `kill -0 N` |
| `killProcess(pid)` | `taskkill /PID N /T /F` | `process.kill(pid, "SIGTERM")` |
| `findExecutable(name)` | `where.exe name` | `which name` |
| `spawnOptions()` | `{ windowsHide: true }` | `{}` |
| `openBrowser(url)` | `cmd /c start "" url` | `xdg-open url` |
| `shellScriptExt()` | `".ps1"` | `".sh"` |
| `shellRunner()` | `"powershell"` | `"bash"` |
| `shellArgs()` | `["-NoProfile","-ExecutionPolicy","Bypass","-File"]` | `[]` |

### 4.2 NEW: `collect-wechat.sh` (`.claude/skills/wechat-skill-2/`)

Bash peer of `collect-wechat.ps1`. Same behavior: `--start`, `--stop`, status display.

Key mappings:
- `$PSScriptRoot` → `${BASH_SOURCE[0]%/*}`
- `Start-Process ... -WindowStyle Hidden` → `nohup bash ... & echo $!`
- `Get-CimInstance Win32_Process` → read `/proc/$pid/cmdline`
- `System.Threading.Mutex` → pid-file-based mutual exclusion
- `Start-Sleep -Milliseconds` → `sleep 0.25`
- UTF-8 encoding → `export LANG=en_US.UTF-8`

### 4.3 NEW: `wechat-approve.sh` (`.claude/skills/wechat-skill-2/`)

Bash peer of `wechat-approve.ps1`. Forwards to `bun run wechat-approve-cli.ts`.

### 4.4 NEW: `start-wechat-auto.sh` (`.claude/hooks/`)

Bash peer of `start-wechat-auto.ps1`. Project-level mutex via pid-file; launches `start-wechat-auto-runner.sh` in background.

### 4.5 NEW: `start-wechat-auto-runner.sh` (`.claude/hooks/`)

Bash peer of `start-wechat-auto-runner.ps1`. Restart loop around `wechat-auto-reply.ts`. Backoff: 2s → 4s → ... → 120s max.

### 4.6 NEW: `stop-wechat-auto.sh` (`.claude/hooks/`)

Bash peer of `stop-wechat-auto.ps1`. Scans `/proc/*/cmdline` for matching bun processes; kills them; removes pid file.

### 4.7 NEW: `wechat-tray.py` (`.claude/hooks/`)

GTK3 system tray using Python `gi` bindings. Dependencies: `python3-gi`, `gir1.2-gtk-3.0`, `gir1.2-appindicator3-0.1`.

Features:
- Start watcher (via `bash start-wechat-auto.sh`)
- Start HTTP server (via `bun run wechat-launcher.ts --hidden`)
- Tray icon with right-click menu: Open GUI, Start/Stop Watcher, Quit
- Tooltip: "WeChat Skill - Running"

### 4.8 MODIFIED: `wechat-launcher.ts`

Changes in `main()`:
- On Linux with no args / `--tray`: spawn `wechat-tray.py` instead of `wechat-tray.exe`
- `startWatcher()`: use `platform.shellRunner()` + `platform.shellArgs()` instead of hardcoded `powershell`
- `findBun()`: use `platform.findExecutable("bun")` instead of `where.exe bun`
- `openBrowser()`: use `platform.openBrowser()` instead of `cmd /c start`

### 4.9 MODIFIED: `wechat-gui-server.ts`

- `psRun()`: use `platform.shellRunner()` + `platform.shellArgs()` instead of hardcoded `powershell`
- `isWatcherRunning()`: use `platform.isProcessAlive()` instead of `tasklist`
- `isWatcherRunning()` no longer reads PID file — delegates to platform

### 4.10 MODIFIED: `wechat-auto-reply.ts` (`.claude/hooks/`)

- `resolveClaudeExecutable()`: use `platform.findExecutable("claude")` instead of `where.exe claude`
- Process kill paths: use `platform.killProcess()` instead of `taskkill`
- `windowsHide` in spawn: conditionally apply via `platform.spawnOptions()`

### 4.11 MODIFIED: `SKILL.md` (`.claude/skills/wechat-skill-2/`)

Add "Linux 用法" section with Bash command variants:
- Start: `bash "${CLAUDE_SKILL_DIR}/collect-wechat.sh" --start`
- Stop: `bash "${CLAUDE_SKILL_DIR}/collect-wechat.sh" --stop`
- Status: `bash "${CLAUDE_SKILL_DIR}/collect-wechat.sh"`
- Approve: `bash "${CLAUDE_SKILL_DIR}/wechat-approve.sh" list`
- GUI: `bun run wechat-gui-server.ts`

### 4.12 MODIFIED: `CLAUDE.md`

Add Linux runtime documentation: `platform.ts` overview, Bash/PS1 coexistence, GTK tray dependencies.

### 4.13 UNCHANGED

- `wechat-send.ts` — no platform calls
- `wechat-approve-cli.ts` — no platform calls
- `classify-test-runner.ts` — no platform calls
- `test-watcher.ts` — no platform calls
- `wechat-skill-gui.html` — pure HTML, no platform calls
- `package.json` — no new npm dependencies

## 5. Data Flow

```
User types: /wechat-skill-2 --start
    │
SKILL.md routes to:
  Win:  powershell ... collect-wechat.ps1 --start
  Linux: bash ... collect-wechat.sh --start
    │
    ▼
start-wechat-auto.sh → runner.sh → wechat-auto-reply.ts (long-lived)
    │
GUI Server (wechat-gui-server.ts) reads state / history / pending files
    │
platform.ts handles all OS-specific operations
```

## 6. Error Handling

- `findExecutable()` failing: throw with clear message including platform-specific diagnostic suggestions
- Process not found when stopping: graceful — `kill -0` fails silently, continue to cleanup
- GTK tray missing on Linux: log warning, fall back to console mode (same as Windows tray-exe missing)
- Pid file stale / race: runner.sh checks if existing PID belongs to a real bun process; if not, overwrites

## 7. Testing Strategy

- Verify each Bash script independently with `bash -n` (syntax check)
- Manual test on Ubuntu: `collect-wechat.sh --start` → verify PID file, verify process running
- `collect-wechat.sh --stop` → verify watcher stopped, PID file removed
- `bun run wechat-gui-server.ts` → verify `http://localhost:3456` serves the GUI
- `wechat-send.ts` → unchanged, verify still works on both platforms
- Existing Windows test (`bun run test-watcher.ts risk`) → must still pass unchanged

## 8. Dependencies (Ubuntu)

```
# Required (pre-installed on most Ubuntu desktop flavors):
python3

# Install if missing:
sudo apt install python3-gi gir1.2-gtk-3.0 gir1.2-appindicator3-0.1
```

## 9. Rejected Alternatives

- **Full TypeScript rewrite of scripts:** Loses shell simplicity; SKILL.md entry becomes complex; Bun `$` template support uncertain in Claude Code skill environment
- **Inline `if win32` branching everywhere:** Scatters platform logic across all files; hard to maintain and test
- **Linux-only SKILL.md copy:** Diverges the skill into two codebases; defeats shared maintenance
