import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { loadTask } from "../src/core/task.js";
import { hashProject, initializeWorkspace } from "../src/core/workspace.js";

const root = path.resolve(import.meta.dirname, "..");

test("initializeWorkspace creates a public instruction and stable starter fingerprint", () => {
  const taskPath = path.join(root, "benchmark", "tasks", "repair-neon-relay-jump.json");
  const { task, taskDirectory } = loadTask(taskPath);
  const source = path.resolve(taskDirectory, task.project.path);
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "gamephanes-workspace-test-"));
  try {
    const result = initializeWorkspace({ task, projectPath: source, workspacePath: workspace });
    const instruction = JSON.parse(fs.readFileSync(result.instructionPath, "utf8"));
    assert.equal(instruction.task_id, task.id);
    assert.equal(instruction.instruction, task.description);
    assert.equal("assertions" in instruction, false);
    assert.equal("harness" in instruction, false);
    assert.equal(result.starterHash, hashProject(workspace));
    assert.equal(JSON.parse(fs.readFileSync(path.join(workspace, ".gamephanes", "workspace.json"))).starter_sha256, result.starterHash);
  } finally {
    fs.rmSync(workspace, { recursive: true, force: true });
  }
});

test("initializeWorkspace refuses to overwrite a non-empty workspace", () => {
  const taskPath = path.join(root, "benchmark", "tasks", "repair-neon-relay-jump.json");
  const { task, taskDirectory } = loadTask(taskPath);
  const source = path.resolve(taskDirectory, task.project.path);
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "gamephanes-workspace-test-"));
  fs.writeFileSync(path.join(workspace, "agent-note.txt"), "keep me");
  try {
    assert.throws(
      () => initializeWorkspace({ task, projectPath: source, workspacePath: workspace }),
      /workspace must be empty/,
    );
  } finally {
    fs.rmSync(workspace, { recursive: true, force: true });
  }
});
