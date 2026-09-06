import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { loadTask } from "../src/core/task.js";

const root = path.resolve(import.meta.dirname, "..");
const tasksDirectory = path.join(root, "benchmark", "tasks");
const docsDirectory = path.join(root, "docs");
const homepage = fs.readFileSync(path.join(docsDirectory, "index.html"), "utf8");

const publicTasks = fs.readdirSync(tasksDirectory)
  .filter((fileName) => fileName.endsWith(".json"))
  .map((fileName) => ({ fileName, task: loadTask(path.join(tasksDirectory, fileName)).task }))
  .filter(({ task }) => task.registry);

test("public tasks have unique registry pages and valid assets", () => {
  const slugs = publicTasks.map(({ task }) => task.registry.slug);
  assert.equal(new Set(slugs).size, slugs.length);

  for (const { fileName, task } of publicTasks) {
    const detailPath = path.join(docsDirectory, "registry", task.registry.slug, "index.html");
    assert.ok(fs.existsSync(detailPath), `missing registry page for ${task.id}`);
    assert.ok(fs.existsSync(path.join(docsDirectory, "assets", task.registry.image)));
    if (task.registry.play_path) {
      assert.ok(fs.existsSync(path.join(docsDirectory, task.registry.play_path)));
    }

    const detail = fs.readFileSync(detailPath, "utf8");
    assert.ok(detail.includes(task.id));
    assert.ok(detail.includes(`benchmark/tasks/${fileName}`));
    assert.doesNotMatch(detail, /\n\+\s+--godot/);
    assert.ok(homepage.includes(`registry/${task.registry.slug}/`));
  }
});

test("registry index links every published task", () => {
  const registryIndex = fs.readFileSync(path.join(docsDirectory, "registry", "index.html"), "utf8");
  for (const { task } of publicTasks) {
    assert.ok(registryIndex.includes(`href="${task.registry.slug}/"`));
  }
  assert.match(registryIndex, /reference environments/);
});
