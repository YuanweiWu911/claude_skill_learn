import { existsSync } from "node:fs";
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
