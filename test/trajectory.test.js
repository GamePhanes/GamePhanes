import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { CodingAgentAdapter, TrajectoryRecorder, validateTrajectory } from "../src/trajectory/recorder.js";

test("TrajectoryRecorder captures coding actions, patches, and evaluator feedback", () => {
  const recorder = new TrajectoryRecorder({
    taskId: "platformer_basic_001",
    agent: "test-agent",
    environment: { engine: "godot", version: "4.x" },
    episodeId: "ep_test_001",
  });
  const adapter = new CodingAgentAdapter({ recorder });

  adapter.recordToolCall({
    tool: "read_file",
    input: { path: "scripts/player.gd" },
    output: { content: "extends CharacterBody2D" },
    cost: { duration_ms: 4, tool_calls: 1 },
  });
  adapter.recordTerminalCommand({
    command: "godot --headless --path . --editor --quit",
    stdout: "Project imported",
    exitCode: 0,
    cost: { duration_ms: 80, tool_calls: 1 },
  });
  adapter.recordPatch({
    files: ["scripts/player.gd"],
    patch: "@@ -1 +1 @@\n-extends Node2D\n+extends CharacterBody2D",
  });
  adapter.recordFeedback({
    report: {
      task_id: "platformer_basic_001",
      total_score: 0.8,
      events: [{ type: "ready" }],
      assertions: [{ id: "ready", passed: true }],
    },
  });
  const trajectory = adapter.finish({ status: "failed", finalScore: 0.8, summary: { reason: "jump assertion failed" } });

  assert.equal(trajectory.trajectory_type, "coding_agent");
  assert.equal(trajectory.steps.length, 4);
  assert.equal(trajectory.steps[0].action.type, "read_file");
  assert.equal(trajectory.steps[1].action.type, "terminal_command");
  assert.equal(trajectory.steps[2].artifacts.patches[0].sha256.length, 64);
  assert.equal(trajectory.steps[3].actor, "evaluator");
  assert.equal(trajectory.steps[3].reward, 0.8);
  assert.doesNotThrow(() => validateTrajectory(trajectory));
});

test("TrajectoryRecorder writes a validated JSON artifact", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "gamephanes-trajectory-test-"));
  try {
    const recorder = new TrajectoryRecorder({ taskId: "sample", episodeId: "ep_write" });
    recorder.finish({ status: "passed", finalScore: 1 });
    const outputPath = recorder.write(path.join(directory, "trajectory.json"));
    const saved = JSON.parse(fs.readFileSync(outputPath, "utf8"));
    assert.equal(saved.episode_id, "ep_write");
    assert.equal(saved.status, "passed");
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
});

test("agent actions reject gameplay-control actions", () => {
  const recorder = new TrajectoryRecorder({ taskId: "sample" });
  assert.throws(
    () => recorder.recordStep({ action: { type: "press_key", input: { key: "SPACE" } } }),
    /supported coding-agent action/,
  );
});

test("evaluator probes cannot contain coding-agent actions", () => {
  const recorder = new TrajectoryRecorder({ taskId: "sample", trajectoryType: "evaluator_probe" });
  assert.throws(
    () => recorder.recordToolCall({ tool: "read_file", input: { path: "main.gd" } }),
    /evaluator_probe cannot contain agent actions/,
  );
});
