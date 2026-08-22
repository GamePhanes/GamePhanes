import fs from "node:fs";
import path from "node:path";
import { validateTaskTaxonomy } from "./taxonomy.js";

const OPERATORS = new Set(["exists", "==", "!=", ">", ">=", "<", "<=", "includes"]);

function requireString(value, field) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${field} must be a non-empty string`);
  }
  return value;
}

function requireArray(value, field) {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error(`${field} must be a non-empty array`);
  }
  return value;
}

export function validateTask(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("task must be a JSON object");
  }
  if (input.schema_version !== 1) {
    throw new Error("schema_version must be 1");
  }

  requireString(input.id, "id");
  requireString(input.title, "title");
  requireString(input.description, "description");
  validateTaskTaxonomy(input.taxonomy);
  requireString(input.project?.path, "project.path");
  requireString(input.evaluation?.harness, "evaluation.harness");

  const timeout = input.evaluation.timeout_seconds ?? 15;
  if (!Number.isFinite(timeout) || timeout <= 0 || timeout > 300) {
    throw new Error("evaluation.timeout_seconds must be between 0 and 300");
  }

  requireArray(input.requirements, "requirements").forEach((requirement, index) => {
    requireString(requirement?.id, `requirements[${index}].id`);
    requireString(requirement?.description, `requirements[${index}].description`);
  });

  const ids = new Set();
  requireArray(input.evaluation.assertions, "evaluation.assertions").forEach((assertion, index) => {
    const prefix = `evaluation.assertions[${index}]`;
    const id = requireString(assertion?.id, `${prefix}.id`);
    if (ids.has(id)) throw new Error(`${prefix}.id must be unique`);
    ids.add(id);
    requireString(assertion.event, `${prefix}.event`);
    const operator = assertion.operator ?? "exists";
    if (!OPERATORS.has(operator)) {
      throw new Error(`${prefix}.operator is not supported`);
    }
    if (operator !== "exists") {
      requireString(assertion.field, `${prefix}.field`);
      if (!("value" in assertion)) throw new Error(`${prefix}.value is required`);
    }
  });

  return {
    ...input,
    evaluation: { ...input.evaluation, timeout_seconds: timeout },
  };
}

export function loadTask(taskPath) {
  const absolutePath = path.resolve(taskPath);
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(absolutePath, "utf8"));
  } catch (error) {
    throw new Error(`cannot read task ${absolutePath}: ${error.message}`);
  }

  const task = validateTask(parsed);
  return {
    task,
    taskPath: absolutePath,
    taskDirectory: path.dirname(absolutePath),
  };
}

export function resolveTaskPath(taskDirectory, relativePath, label) {
  const resolved = path.resolve(taskDirectory, relativePath);
  if (!fs.existsSync(resolved)) {
    throw new Error(`${label} does not exist: ${resolved}`);
  }
  return resolved;
}
