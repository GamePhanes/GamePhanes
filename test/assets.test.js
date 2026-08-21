import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { loadManifest, validateManifest } from "../src/assets/manifest.js";

test("loadManifest validates the reproducible procedural asset pack", () => {
  const result = loadManifest(path.resolve("assets/manifest.json"));
  assert.equal(result.manifest.assets.length, 3);
  assert.equal(result.manifest.assets[0].source, "procedural");
});

test("validateManifest rejects duplicate IDs and unsupported sources", () => {
  const base = {
    schema_version: 1,
    id: "sample",
    assets: [{ id: "asset", type: "texture_2d", source: "procedural", license: "MIT", files: [] }],
  };
  const duplicate = structuredClone(base);
  duplicate.assets.push(structuredClone(base.assets[0]));
  assert.throws(() => validateManifest(duplicate), /must be unique/);

  const unsupported = structuredClone(base);
  unsupported.assets[0].source = "unknown";
  assert.throws(() => validateManifest(unsupported), /source is not supported/);
});

test("validateManifest prevents asset paths from escaping the manifest directory", () => {
  const manifest = {
    schema_version: 1,
    id: "sample",
    assets: [{ id: "asset", type: "texture_2d", source: "curated", license: "CC0", files: ["../secret.png"] }],
  };
  assert.throws(() => validateManifest(manifest, path.resolve("assets"), { checkFiles: false }), /escapes/);
});
