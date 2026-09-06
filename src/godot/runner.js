import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { parseEvents } from "../evaluation/protocol.js";
import { runProcess } from "../runtime/process.js";
import { copyProject } from "../core/workspace.js";

function prepareSandbox(projectPath, harnessPath) {
  const sandbox = fs.mkdtempSync(path.join(os.tmpdir(), "gamephanes-"));
  copyProject(projectPath, sandbox);
  const harnessDirectory = path.join(sandbox, ".gamephanes");
  fs.rmSync(harnessDirectory, { recursive: true, force: true });
  fs.mkdirSync(harnessDirectory, { recursive: true });
  fs.copyFileSync(harnessPath, path.join(harnessDirectory, "harness.gd"));
  return sandbox;
}

export async function runGodotTask({ godotPath, projectPath, harnessPath, timeoutSeconds }) {
  const sandbox = prepareSandbox(projectPath, harnessPath);
  try {
    const validation = await runProcess(
      godotPath,
      ["--headless", "--path", sandbox, "--editor", "--quit"],
      { timeoutMs: timeoutSeconds * 1000 },
    );

    if (validation.exitCode !== 0 || validation.timedOut || validation.outputExceeded) {
      return { sandboxed: true, validation, playtest: null, events: [], protocolErrors: [] };
    }

    const playtest = await runProcess(
      godotPath,
      ["--headless", "--path", sandbox, "--script", "res://.gamephanes/harness.gd"],
      { timeoutMs: timeoutSeconds * 1000 },
    );
    const parsed = parseEvents(`${playtest.stdout}\n${playtest.stderr}`);
    return { sandboxed: true, validation, playtest, ...parsed };
  } finally {
    fs.rmSync(sandbox, { recursive: true, force: true });
  }
}
