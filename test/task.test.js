import test from "node:test";
import assert from "node:assert/strict";
import { validateTask } from "../src/core/task.js";

const validTask = {
  schema_version: 1,
  id: "sample",
  title: "Sample",
  description: "A sample task",
  taxonomy: { domain: "engine_runtime", subdomain: "engine_apis", task_type: "bug_fix" },
  project: { path: "project" },
  requirements: [{ id: "runs", description: "It runs" }],
  evaluation: {
    harness: "harness.gd",
    assertions: [{ id: "ready", event: "ready" }],
  },
};

test("validateTask applies the default timeout", () => {
  const result = validateTask(validTask);
  assert.equal(result.evaluation.timeout_seconds, 15);
});

test("validateTask rejects duplicate assertion IDs", () => {
  const task = structuredClone(validTask);
  task.evaluation.assertions.push({ id: "ready", event: "done" });
  assert.throws(() => validateTask(task), /must be unique/);
});

test("validateTask requires a comparison field and value", () => {
  const task = structuredClone(validTask);
  task.evaluation.assertions[0].operator = ">";
  assert.throws(() => validateTask(task), /field must be/);
});

test("validateTask rejects a subdomain outside its domain", () => {
  const task = structuredClone(validTask);
  task.taxonomy.subdomain = "combat";
  assert.throws(() => validateTask(task), /subdomain is not supported/);
});
