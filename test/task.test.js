import test from "node:test";
import assert from "node:assert/strict";
import { validateTask } from "../src/core/task.js";

const validTask = {
  schema_version: 1,
  id: "sample",
  title: "Sample",
  description: "A sample task",
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
