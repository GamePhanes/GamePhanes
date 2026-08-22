import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

export const TRAJECTORY_SCHEMA_VERSION = 1;

export const CODING_AGENT_ACTIONS = Object.freeze([
  "terminal_command",
  "read_file",
  "write_file",
  "apply_patch",
  "run_godot",
  "run_playtest",
  "inspect_scene",
  "take_screenshot",
  "repair",
]);

export const TRAJECTORY_TYPES = Object.freeze(["coding_agent", "evaluator_probe"]);
const ACTION_SET = new Set(CODING_AGENT_ACTIONS);
const TRAJECTORY_TYPE_SET = new Set(TRAJECTORY_TYPES);
const ACTORS = new Set(["agent", "evaluator", "system"]);
const STATUSES = new Set(["running", "passed", "failed", "error", "cancelled"]);

function requireString(value, field) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${field} must be a non-empty string`);
  }
  return value;
}

function cloneJson(value, field = "value") {
  if (value === undefined) return undefined;
  try {
    return structuredClone(value);
  } catch (error) {
    throw new Error(`${field} must be JSON-serializable: ${error.message}`);
  }
}

function normalizeObject(value, field) {
  if (value === undefined) return {};
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${field} must be an object`);
  }
  return cloneJson(value, field);
}

function hashText(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function compactExecution(execution) {
  return {
    sandboxed: execution.sandboxed,
    validation: {
      exit_code: execution.validation?.exitCode ?? null,
      timed_out: execution.validation?.timedOut ?? false,
      output_exceeded: execution.validation?.outputExceeded ?? false,
      duration_ms: execution.validation?.durationMs ?? null,
      stdout: execution.validation?.stdout ?? "",
      stderr: execution.validation?.stderr ?? "",
    },
    playtest: execution.playtest
      ? {
        exit_code: execution.playtest.exitCode ?? null,
        timed_out: execution.playtest.timedOut ?? false,
        output_exceeded: execution.playtest.outputExceeded ?? false,
        duration_ms: execution.playtest.durationMs ?? null,
        stdout: execution.playtest.stdout ?? "",
        stderr: execution.playtest.stderr ?? "",
      }
      : null,
    events: execution.events ?? [],
    protocol_errors: execution.protocolErrors ?? [],
  };
}

export function validateTrajectory(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("trajectory must be a JSON object");
  }
  if (input.schema_version !== TRAJECTORY_SCHEMA_VERSION) {
    throw new Error(`schema_version must be ${TRAJECTORY_SCHEMA_VERSION}`);
  }
  requireString(input.episode_id, "episode_id");
  requireString(input.task_id, "task_id");
  requireString(input.agent, "agent");
  requireString(input.trajectory_type, "trajectory_type");
  if (!TRAJECTORY_TYPE_SET.has(input.trajectory_type)) throw new Error("trajectory_type is not supported");
  if (!input.environment || typeof input.environment !== "object" || Array.isArray(input.environment)) {
    throw new Error("environment must be an object");
  }
  if (!Array.isArray(input.steps)) throw new Error("steps must be an array");
  input.steps.forEach((step, index) => {
    if (!step || typeof step !== "object" || Array.isArray(step)) {
      throw new Error(`steps[${index}] must be an object`);
    }
    if (step.step !== index) throw new Error(`steps[${index}].step must be ${index}`);
    if (!ACTORS.has(step.actor)) throw new Error(`steps[${index}].actor is not supported`);
    if (input.trajectory_type === "evaluator_probe" && step.actor === "agent") {
      throw new Error(`steps[${index}] evaluator_probe cannot contain agent actions`);
    }
    requireString(step.action?.type, `steps[${index}].action.type`);
    if (step.actor === "agent" && !ACTION_SET.has(step.action.type)) {
      throw new Error(`steps[${index}].action.type is not a supported coding-agent action`);
    }
    if (typeof step.reward !== "number" || !Number.isFinite(step.reward)) {
      throw new Error(`steps[${index}].reward must be a finite number`);
    }
    normalizeObject(step.observation, `steps[${index}].observation`);
    normalizeObject(step.result, `steps[${index}].result`);
    if (step.cost !== undefined) normalizeObject(step.cost, `steps[${index}].cost`);
  });
  if (input.status !== undefined && !STATUSES.has(input.status)) {
    throw new Error("status is not supported");
  }
  if (input.final_score !== undefined && (typeof input.final_score !== "number" || !Number.isFinite(input.final_score))) {
    throw new Error("final_score must be a finite number");
  }
  return input;
}

export class TrajectoryRecorder {
  constructor({ taskId, agent = "unknown", environment = {}, episodeId, metadata = {}, trajectoryType = "coding_agent" } = {}) {
    const normalizedType = requireString(trajectoryType, "trajectory_type");
    if (!TRAJECTORY_TYPE_SET.has(normalizedType)) throw new Error("trajectory_type is not supported");
    this.trajectory = {
      schema_version: TRAJECTORY_SCHEMA_VERSION,
      trajectory_type: normalizedType,
      episode_id: episodeId ?? `ep_${Date.now()}_${crypto.randomBytes(4).toString("hex")}`,
      task_id: requireString(taskId, "task_id"),
      agent: requireString(agent, "agent"),
      environment: normalizeObject(environment, "environment"),
      metadata: normalizeObject(metadata, "metadata"),
      started_at: new Date().toISOString(),
      status: "running",
      steps: [],
    };
  }

  recordStep({ actor = "agent", action, observation = {}, result = {}, reward = 0, cost, artifacts, timestamp } = {}) {
    if (this.trajectory.status !== "running") throw new Error("cannot record a step after finish");
    if (!ACTORS.has(actor)) throw new Error("actor is not supported");
    if (this.trajectory.trajectory_type === "evaluator_probe" && actor === "agent") {
      throw new Error("evaluator_probe cannot contain agent actions");
    }
    requireString(action?.type, "action.type");
    if (actor === "agent" && !ACTION_SET.has(action.type)) {
      throw new Error(`action.type must be a supported coding-agent action: ${CODING_AGENT_ACTIONS.join(", ")}`);
    }
    if (typeof reward !== "number" || !Number.isFinite(reward)) throw new Error("reward must be a finite number");
    const step = {
      step: this.trajectory.steps.length,
      timestamp: timestamp ?? new Date().toISOString(),
      actor,
      action: normalizeObject(action, "action"),
      observation: normalizeObject(observation, "observation"),
      result: normalizeObject(result, "result"),
      reward,
    };
    if (cost !== undefined) step.cost = normalizeObject(cost, "cost");
    if (artifacts !== undefined) step.artifacts = normalizeObject(artifacts, "artifacts");
    this.trajectory.steps.push(step);
    return cloneJson(step, "step");
  }

  recordToolCall({ tool, input = {}, output = {}, observation = {}, result = {}, cost, artifacts } = {}) {
    requireString(tool, "tool");
    return this.recordStep({
      actor: "agent",
      action: { type: tool, input },
      observation,
      result: { ...result, output },
      cost,
      artifacts,
    });
  }

  recordTerminalCommand({ command, stdout = "", stderr = "", exitCode = null, observation = {}, result = {}, cost } = {}) {
    requireString(command, "command");
    return this.recordToolCall({
      tool: "terminal_command",
      input: { command },
      output: { stdout, stderr, exit_code: exitCode },
      observation,
      result,
      cost,
    });
  }

  recordPatch({ files = [], patch, result = {}, observation = {}, cost } = {}) {
    if (!Array.isArray(files)) throw new Error("files must be an array");
    const patchText = patch ?? "";
    requireString(patchText, "patch");
    return this.recordToolCall({
      tool: "apply_patch",
      input: { files, patch_sha256: hashText(patchText) },
      output: { files, patch_sha256: hashText(patchText) },
      observation,
      result,
      cost,
      artifacts: { patches: [{ files, sha256: hashText(patchText), content: patchText }] },
    });
  }

  recordFeedback({ report, execution, observation = {}, cost } = {}) {
    if (!report || typeof report !== "object" || Array.isArray(report)) throw new Error("report must be an object");
    const feedbackExecution = execution ?? report.execution;
    return this.recordStep({
      actor: "evaluator",
      action: { type: "run_playtest", input: { task_id: report.task_id } },
      observation: { ...observation, events: report.events ?? feedbackExecution?.events ?? [], assertions: report.assertions ?? [] },
      result: { report },
      reward: report.total_score ?? 0,
      cost,
      artifacts: feedbackExecution ? { logs: compactExecution(feedbackExecution) } : undefined,
    });
  }

  finish({ status, finalScore, summary = {} } = {}) {
    if (this.trajectory.status !== "running") throw new Error("trajectory is already finished");
    if (!STATUSES.has(status) || status === "running") throw new Error("finish status must be passed, failed, error, or cancelled");
    this.trajectory.finished_at = new Date().toISOString();
    this.trajectory.status = status;
    if (finalScore !== undefined) {
      if (typeof finalScore !== "number" || !Number.isFinite(finalScore)) throw new Error("finalScore must be a finite number");
      this.trajectory.final_score = finalScore;
    }
    this.trajectory.summary = normalizeObject(summary, "summary");
    return this.toJSON();
  }

  toJSON() {
    return cloneJson(this.trajectory, "trajectory");
  }

  write(filePath) {
    const absolutePath = path.resolve(filePath);
    validateTrajectory(this.trajectory);
    fs.mkdirSync(path.dirname(absolutePath), { recursive: true });
    const temporaryPath = `${absolutePath}.${process.pid}.tmp`;
    fs.writeFileSync(temporaryPath, `${JSON.stringify(this.trajectory, null, 2)}\n`);
    fs.renameSync(temporaryPath, absolutePath);
    return absolutePath;
  }
}

export class CodingAgentAdapter {
  constructor({ recorder, agent } = {}) {
    if (!(recorder instanceof TrajectoryRecorder)) throw new Error("recorder must be a TrajectoryRecorder");
    this.recorder = recorder;
    this.agent = agent ?? recorder.trajectory.agent;
  }

  recordToolCall(input) {
    return this.recorder.recordToolCall(input);
  }

  recordTerminalCommand(input) {
    return this.recorder.recordTerminalCommand(input);
  }

  recordPatch(input) {
    return this.recorder.recordPatch(input);
  }

  recordFeedback(input) {
    return this.recorder.recordFeedback(input);
  }

  finish(input) {
    return this.recorder.finish(input);
  }
}
