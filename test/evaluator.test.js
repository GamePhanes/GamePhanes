import test from "node:test";
import assert from "node:assert/strict";
import { evaluateAssertions } from "../src/evaluation/evaluator.js";
import { parseEvents } from "../src/evaluation/protocol.js";

test("parseEvents extracts structured events from noisy engine logs", () => {
  const output = [
    "Godot Engine 4.x",
    'GAMEPHANES_EVENT {"type":"jump","state":{"velocity_y":-240}}',
    "debug text",
  ].join("\n");
  const result = parseEvents(output);
  assert.equal(result.events.length, 1);
  assert.equal(result.events[0].state.velocity_y, -240);
  assert.deepEqual(result.protocolErrors, []);
});

test("parseEvents still accepts the legacy GameBuddy event prefix", () => {
  const result = parseEvents('GAMEBUDDY_EVENT {"type":"legacy_ready"}');
  assert.equal(result.events[0].type, "legacy_ready");
});

test("evaluateAssertions supports nested fields and numeric comparisons", () => {
  const assertions = [
    { id: "ready", event: "ready" },
    { id: "jump", event: "jump", field: "state.velocity_y", operator: "<", value: 0 },
  ];
  const events = [{ type: "ready" }, { type: "jump", state: { velocity_y: -240 } }];
  const result = evaluateAssertions(assertions, events);
  assert.equal(result.score, 1);
  assert.equal(result.passed, 2);
});

test("evaluateAssertions reports unmet conditions", () => {
  const assertions = [{ id: "coin", event: "coin", field: "score", operator: ">=", value: 1 }];
  const result = evaluateAssertions(assertions, [{ type: "coin", score: 0 }]);
  assert.equal(result.score, 0);
  assert.match(result.results[0].reason, /no coin event/);
});
