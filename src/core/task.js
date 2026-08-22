import fs from "node:fs";
import path from "node:path";
import { validateTaskTaxonomy } from "./taxonomy.js";

const OPERATORS = new Set(["exists", "==", "!=", ">", ">=", "<", "<=", "includes"]);
const DIFFICULTIES = new Set(["unrated", "easy", "medium", "hard", "expert"]);
const REGISTRY_KINDS = new Set(["reference_environment", "coding_challenge"]);
const EVALUATOR_VISIBILITY = new Set(["public_reference", "public_development", "sealed"]);

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

function validateRegistryMetadata(input) {
  if (input === undefined) return;
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("registry must be an object");
  }
  requireString(input.slug, "registry.slug");
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(input.slug)) {
    throw new Error("registry.slug must be a lowercase URL slug");
  }
  requireString(input.version, "registry.version");
  if (!REGISTRY_KINDS.has(input.kind)) throw new Error("registry.kind is not supported");
  if (!EVALUATOR_VISIBILITY.has(input.evaluator_visibility)) {
    throw new Error("registry.evaluator_visibility is not supported");
  }
  if (input.kind === "reference_environment" && input.evaluator_visibility !== "public_reference") {
    throw new Error("reference environments must use public_reference evaluation");
  }
  if (input.kind === "coding_challenge" && input.evaluator_visibility === "public_reference") {
    throw new Error("coding challenges cannot use public_reference evaluation");
  }
  if (!DIFFICULTIES.has(input.difficulty)) throw new Error("registry.difficulty is not supported");
  requireString(input.author, "registry.author");
  requireString(input.image, "registry.image");
  if (input.image.includes("/") || input.image.includes("\\")) {
    throw new Error("registry.image must be an asset filename");
  }
  if (input.play_path !== undefined) {
    requireString(input.play_path, "registry.play_path");
    if (!/^(?:[a-z0-9]+(?:-[a-z0-9]+)*\/)+$/.test(input.play_path)) {
      throw new Error("registry.play_path must be a safe relative directory path");
    }
  }
  const tags = requireArray(input.tags, "registry.tags");
  const uniqueTags = new Set();
  tags.forEach((tag, index) => {
    requireString(tag, `registry.tags[${index}]`);
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(tag)) {
      throw new Error(`registry.tags[${index}] must be a lowercase slug`);
    }
    if (uniqueTags.has(tag)) throw new Error(`registry.tags[${index}] must be unique`);
    uniqueTags.add(tag);
  });
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
  validateRegistryMetadata(input.registry);
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
