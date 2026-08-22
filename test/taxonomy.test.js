import assert from "node:assert/strict";
import test from "node:test";
import { TARGET_TASK_MIX, TASK_TAXONOMY, TASK_TYPES } from "../src/core/taxonomy.js";

test("target task taxonomy defines a 100-task benchmark mix", () => {
  const total = Object.values(TARGET_TASK_MIX)
    .flatMap((domain) => Object.values(domain))
    .reduce((sum, count) => sum + count, 0);
  assert.equal(total, 100);
});

test("target mix uses only declared domains and subdomains", () => {
  for (const [domain, mix] of Object.entries(TARGET_TASK_MIX)) {
    assert.ok(TASK_TAXONOMY[domain]);
    assert.deepEqual(Object.keys(mix), [...TASK_TAXONOMY[domain]]);
  }
  assert.ok(TASK_TYPES.includes("reference_environment"));
  assert.ok(TASK_TYPES.includes("bug_fix"));
});
