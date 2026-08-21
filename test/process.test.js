import test from "node:test";
import assert from "node:assert/strict";
import { runProcess } from "../src/runtime/process.js";

test("runProcess captures output and exit status", async () => {
  const result = await runProcess(process.execPath, ["-e", "console.log('ok')"], { timeoutMs: 2_000 });
  assert.equal(result.exitCode, 0);
  assert.equal(result.stdout.trim(), "ok");
  assert.equal(result.timedOut, false);
});

test("runProcess terminates commands that exceed the timeout", async () => {
  const result = await runProcess(process.execPath, ["-e", "setTimeout(() => {}, 5000)"], { timeoutMs: 50 });
  assert.equal(result.timedOut, true);
});
