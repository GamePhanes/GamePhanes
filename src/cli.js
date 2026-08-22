import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { parseArgs } from "node:util";
import { evaluateAssertions } from "./evaluation/evaluator.js";
import { findGodot } from "./godot/discovery.js";
import { runGodotTask } from "./godot/runner.js";
import { loadTask, resolveTaskPath } from "./core/task.js";
import { loadManifest } from "./assets/manifest.js";
import { TrajectoryRecorder, validateTrajectory } from "./trajectory/recorder.js";

const HELP = `GamePhanes - build, playtest, and evaluate Godot games

Usage:
  gamephanes doctor [--godot PATH]
  gamephanes validate <task.json>
  gamephanes run <task.json> [--godot PATH] [--report PATH] [--trajectory PATH] [--agent ID]
  gamephanes trajectory validate <trajectory.json>
  gamephanes assets validate <manifest.json>
  gamephanes assets list <manifest.json>
`;

function parseOptions(args, definitions) {
  return parseArgs({ args, options: definitions, allowPositionals: true, strict: true });
}

function printJson(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

async function doctor(args) {
  const { values } = parseOptions(args, { godot: { type: "string" } });
  const godotPath = findGodot(values.godot);
  const result = {
    node: { ok: true, version: process.version },
    godot: godotPath
      ? { ok: true, path: godotPath }
      : { ok: false, message: "Set GAMEPHANES_GODOT or pass --godot PATH." },
  };
  printJson(result);
  if (!godotPath) process.exitCode = 1;
}

function validate(args) {
  const { positionals } = parseOptions(args, {});
  if (positionals.length !== 1) throw new Error("validate expects one task file");
  const { task, taskDirectory, taskPath } = loadTask(positionals[0]);
  resolveTaskPath(taskDirectory, task.project.path, "project");
  resolveTaskPath(taskDirectory, task.evaluation.harness, "harness");
  printJson({ valid: true, task_id: task.id, task_path: taskPath });
}

async function run(args) {
  const { values, positionals } = parseOptions(args, {
    godot: { type: "string" },
    report: { type: "string" },
    trajectory: { type: "string" },
    agent: { type: "string" },
  });
  if (positionals.length !== 1) throw new Error("run expects one task file");

  const { task, taskDirectory } = loadTask(positionals[0]);
  const projectPath = resolveTaskPath(taskDirectory, task.project.path, "project");
  const harnessPath = resolveTaskPath(taskDirectory, task.evaluation.harness, "harness");
  const godotPath = findGodot(values.godot);
  if (!godotPath) throw new Error("Godot was not found. Set GAMEPHANES_GODOT or pass --godot PATH.");

  const execution = await runGodotTask({
    godotPath,
    projectPath,
    harnessPath,
    timeoutSeconds: task.evaluation.timeout_seconds,
  });
  const evaluation = evaluateAssertions(task.evaluation.assertions, execution.events);
  const buildSuccess = execution.validation.exitCode === 0 && !execution.validation.timedOut;
  const runtimeSuccess = execution.playtest?.exitCode === 0 && !execution.playtest.timedOut;
  const totalScore = 0.2 * Number(buildSuccess) + 0.2 * Number(runtimeSuccess) + 0.6 * evaluation.score;
  const report = {
    schema_version: 1,
    task_id: task.id,
    created_at: new Date().toISOString(),
    build_success: buildSuccess,
    runtime_success: runtimeSuccess,
    functional_score: evaluation.score,
    total_score: Number(totalScore.toFixed(4)),
    assertions: evaluation.results,
    events: execution.events,
    protocol_errors: execution.protocolErrors,
    execution: {
      sandboxed: execution.sandboxed,
      validation_ms: execution.validation.durationMs,
      playtest_ms: execution.playtest?.durationMs ?? null,
    },
  };

  let trajectoryPath;
  if (values.trajectory) {
    const trajectory = new TrajectoryRecorder({
      taskId: task.id,
      agent: values.agent ?? "evaluator",
      trajectoryType: "evaluator_probe",
      environment: { engine: "godot", runner: "gamephanes", runner_version: 1 },
      metadata: { source: "gamephanes run", note: "Evaluator-controlled probe; not a gameplay-control rollout." },
    });
    trajectory.recordFeedback({
      report,
      execution,
      cost: {
        validation_ms: execution.validation.durationMs,
        playtest_ms: execution.playtest?.durationMs ?? null,
      },
    });
    trajectory.finish({
      status: report.total_score === 1 ? "passed" : "failed",
      finalScore: report.total_score,
      summary: { build_success: buildSuccess, runtime_success: runtimeSuccess },
    });
    trajectoryPath = trajectory.write(values.trajectory);
    report.trajectory_path = trajectoryPath;
  }

  if (values.report) {
    const reportPath = path.resolve(values.report);
    fs.mkdirSync(path.dirname(reportPath), { recursive: true });
    fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  }
  printJson(report);
  if (report.total_score < 1) process.exitCode = 2;
}

function trajectory(args) {
  const { positionals } = parseOptions(args, {});
  if (positionals.length !== 2 || positionals[0] !== "validate") {
    throw new Error("trajectory expects validate followed by a trajectory file");
  }
  const trajectoryPath = path.resolve(positionals[1]);
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(trajectoryPath, "utf8"));
  } catch (error) {
    throw new Error(`cannot read trajectory ${trajectoryPath}: ${error.message}`);
  }
  validateTrajectory(parsed);
  printJson({ valid: true, trajectory_path: trajectoryPath, episode_id: parsed.episode_id, steps: parsed.steps.length });
}

function assets(args) {
  const [subcommand, manifestPath] = args;
  if (!subcommand || !manifestPath || !["validate", "list"].includes(subcommand)) {
    throw new Error("assets expects validate or list followed by a manifest file");
  }
  const { manifest, manifestPath: absolutePath } = loadManifest(manifestPath);
  if (subcommand === "list") {
    printJson({
      valid: true,
      manifest_id: manifest.id,
      manifest_path: absolutePath,
      assets: manifest.assets.map(({ id, type, source, license }) => ({ id, type, source, license })),
    });
    return;
  }
  printJson({
    valid: true,
    manifest_id: manifest.id,
    manifest_path: absolutePath,
    asset_count: manifest.assets.length,
  });
}

export async function main(args) {
  const [command, ...rest] = args;
  switch (command) {
    case "doctor": return doctor(rest);
    case "validate": return validate(rest);
    case "run": return run(rest);
    case "assets": return assets(rest);
    case "trajectory": return trajectory(rest);
    case "help":
    case "--help":
    case "-h":
    case undefined:
      process.stdout.write(HELP);
      return;
    default:
      throw new Error(`unknown command: ${command}\n\n${HELP}`);
  }
}
