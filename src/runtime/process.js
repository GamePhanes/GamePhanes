import { spawn } from "node:child_process";

export function runProcess(executable, args, options = {}) {
  const timeoutMs = options.timeoutMs ?? 15_000;
  const maxOutputBytes = options.maxOutputBytes ?? 2_000_000;

  return new Promise((resolve, reject) => {
    const startedAt = Date.now();
    const child = spawn(executable, args, {
      cwd: options.cwd,
      env: options.env ?? process.env,
      windowsHide: true,
      shell: false,
    });

    let stdout = "";
    let stderr = "";
    let timedOut = false;
    let outputExceeded = false;

    const collect = (target, chunk) => {
      const text = chunk.toString();
      if (Buffer.byteLength(stdout) + Buffer.byteLength(stderr) + Buffer.byteLength(text) > maxOutputBytes) {
        outputExceeded = true;
        child.kill();
        return target;
      }
      return target + text;
    };

    child.stdout.on("data", (chunk) => { stdout = collect(stdout, chunk); });
    child.stderr.on("data", (chunk) => { stderr = collect(stderr, chunk); });
    child.on("error", reject);

    const timer = setTimeout(() => {
      timedOut = true;
      child.kill();
    }, timeoutMs);

    child.on("close", (exitCode, signal) => {
      clearTimeout(timer);
      resolve({
        exitCode,
        signal,
        stdout,
        stderr,
        timedOut,
        outputExceeded,
        durationMs: Date.now() - startedAt,
      });
    });
  });
}
