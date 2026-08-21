import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { parseArgs } from "node:util";
import { evaluateAssertions } from "./evaluation/evaluator.js";
import { findGodot } from "./godot/discovery.js";
import { runGodotTask } from "./godot/runner.js";
import { loadTask, resolveTaskPath } from "./core/task.js";

const HELP = `GamePhanes - build, playtest, and evaluate Godot games

Usage:
  gamephanes doctor [--godot PATH]
  gamephanes validate <task.json>
  gamephanes run <task.json> [--godot PATH] [--report PATH]
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
    protocol_errors: execution.protocolErrors,
    execution: {
      sandboxed: execution.sandboxed,
      validation_ms: execution.validation.durationMs,
      playtest_ms: execution.playtest?.durationMs ?? null,
    },
  };

  if (values.report) {
    const reportPath = path.resolve(values.report);
    fs.mkdirSync(path.dirname(reportPath), { recursive: true });
    fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`);
  }
  printJson(report);
  if (report.total_score < 1) process.exitCode = 2;
}

export async function main(args) {
  const [command, ...rest] = args;
  switch (command) {
    case "doctor": return doctor(rest);
    case "validate": return validate(rest);
    case "run": return run(rest);
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
