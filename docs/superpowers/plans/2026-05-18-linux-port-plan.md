# Linux (Ubuntu) Port for wechat-skill — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make wechat-skill-2 work on Ubuntu via platform.ts abstraction layer + Bash peer scripts, preserving full Windows compatibility.

**Architecture:** Add `platform.ts` (OS abstraction module) that all TS files use instead of direct Windows API calls. Create 5 Bash `.sh` peer scripts alongside existing `.ps1` scripts. Add GTK3 Python system tray for Linux. Update SKILL.md/CLAUDE.md with dual-platform documentation.

**Tech Stack:** TypeScript/Bun, Bash, Python3 + GTK3 (gi), existing PowerShell preserved

**Design Spec:** `docs/superpowers/specs/2026-05-18-linux-port-design.md`

---

### Task 1: Create `platform.ts` abstraction layer

**Files:**
- Create: `platform.ts`

- [ ] **Step 1: Write the platform abstraction code**

```typescript
import { existsSync, readFileSync } from "node:fs";
import { spawnSync, type SpawnOptions } from "node:child_process";

const isWin = process.platform === "win32";
const isLin = process.platform === "linux";

export function isWindows(): boolean { return isWin; }
export function isLinux(): boolean { return isLin; }

export function isProcessAlive(pid: number): boolean {
  if (!Number.isFinite(pid) || pid <= 0) return false;
  if (isWin) {
    try {
      const r = spawnSync("tasklist", ["/FI", `PID eq ${pid}`, "/FO", "CSV", "/NH"], {
        encoding: "utf-8", timeout: 5000, windowsHide: true,
      });
      return r.stdout.includes(`"${pid}"`);
    } catch { return false; }
  } else {
    // Linux: check /proc and send signal 0
    if (!existsSync(`/proc/${pid}`)) return false;
    try {
      process.kill(pid, 0);
      return true;
    } catch { return false; }
  }
}

export function killProcess(pid: number, signal: string = "SIGTERM"): boolean {
  if (!Number.isFinite(pid) || pid <= 0) return false;
  if (isWin) {
    try {
      const r = spawnSync("taskkill", ["/PID", String(pid), "/T", "/F"], {
        encoding: "utf-8", timeout: 5000, windowsHide: true,
      });
      return r.status === 0;
    } catch { return false; }
  } else {
    try {
      process.kill(pid, signal as any);
      return true;
    } catch { return false; }
  }
}

export function findExecutable(name: string): string | null {
  const cmd = isWin ? "where.exe" : "which";
  try {
    const r = spawnSync(cmd, [name], { encoding: "utf-8", timeout: 5000, windowsHide: true });
    const first = (r.stdout || "").split(/\r?\n/)[0]?.trim();
    return (first && existsSync(first)) ? first : (isWin ? `${name}.exe` : name);
  } catch {
    return isWin ? `${name}.exe` : name;
  }
}

export function spawnOptions(): SpawnOptions {
  return isWin ? { windowsHide: true } : {};
}

export function openBrowser(url: string): void {
  const cmd = isWin ? "cmd.exe" : "xdg-open";
  const args = isWin ? ["/c", "start", "", url] : [url];
  try {
    spawnSync(cmd, args, { timeout: 8000, windowsHide: true });
  } catch {}
}

export function shellScriptExt(): ".ps1" | ".sh" {
  return isWin ? ".ps1" : ".sh";
}

export function shellRunner(): string {
  return isWin ? "powershell" : "bash";
}

export function shellArgs(): string[] {
  return isWin ? ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File"] : [];
}
```

- [ ] **Step 2: Commit**

```bash
git add platform.ts
git commit -m "feat: add platform.ts abstraction layer"
```

### Task 2: Create Bash peer scripts

**Files:**
- Create: `.claude/skills/wechat-skill-2/collect-wechat.sh`
- Create: `.claude/skills/wechat-skill-2/wechat-approve.sh`
- Create: `.claude/hooks/start-wechat-auto.sh`
- Create: `.claude/hooks/start-wechat-auto-runner.sh`
- Create: `.claude/hooks/stop-wechat-auto.sh`

- [ ] **Step 1: Create `collect-wechat.sh`** (logic matches `.ps1`)
- [ ] **Step 2: Create `wechat-approve.sh`**
- [ ] **Step 3: Create `hooks/start-wechat-auto.sh`** (uses `nohup`)
- [ ] **Step 4: Create `hooks/start-wechat-auto-runner.sh`** (loop with backoff)
- [ ] **Step 5: Create `hooks/stop-wechat-auto.sh`** (kills by pattern)
- [ ] **Step 6: Commit**

```bash
git add .claude/skills/wechat-skill-2/*.sh .claude/hooks/*.sh
git commit -m "feat: add bash peer scripts for linux"
```

### Task 3: Refactor TypeScript files to use `platform.ts`

**Files:**
- Modify: `wechat-launcher.ts`
- Modify: `wechat-gui-server.ts`
- Modify: `wechat-auto-reply.ts`

- [ ] **Step 1: Refactor `wechat-launcher.ts`**
- [ ] **Step 2: Refactor `wechat-gui-server.ts`**
- [ ] **Step 3: Refactor `wechat-auto-reply.ts`**
- [ ] **Step 4: Commit**

```bash
git add wechat-launcher.ts wechat-gui-server.ts .claude/hooks/wechat-auto-reply.ts
git commit -m "refactor: use platform.ts abstraction in TypeScript files"
```

### Task 4: Add GTK3 System Tray for Linux

**Files:**
- Create: `.claude/hooks/wechat-tray.py`
- Modify: `wechat-launcher.ts`

- [ ] **Step 1: Create `wechat-tray.py`**
- [ ] **Step 2: Update `wechat-launcher.ts` to launch `wechat-tray.py` on Linux**
- [ ] **Step 3: Commit**

```bash
git add .claude/hooks/wechat-tray.py wechat-launcher.ts
git commit -m "feat: add linux gtk3 system tray"
```

### Task 5: Update Documentation

**Files:**
- Modify: `.claude/skills/wechat-skill-2/SKILL.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update `SKILL.md` with Linux commands**
- [ ] **Step 2: Update `CLAUDE.md` with platform info**
- [ ] **Step 3: Commit**

```bash
git add .claude/skills/wechat-skill-2/SKILL.md CLAUDE.md
git commit -m "docs: update skill and repo documentation for linux support"
```
