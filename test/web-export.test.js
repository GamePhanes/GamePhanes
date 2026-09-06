import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const playRoot = path.join(root, "docs", "play");

test("Web showcase uses one shared runtime and six playable packages", () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(playRoot, "manifest.json"), "utf8"));
  assert.equal(manifest.games.length, 6);
  assert.ok(fs.statSync(path.join(playRoot, "runtime", "game.wasm")).size > 1_000_000);

  for (const game of manifest.games) {
    const gameDir = path.join(playRoot, game.slug);
    const shell = fs.readFileSync(path.join(gameDir, "game.html"), "utf8");
    const player = fs.readFileSync(path.join(gameDir, "index.html"), "utf8");
    assert.ok(fs.statSync(path.join(gameDir, "game.pck")).size > 0);
    assert.ok(fs.existsSync(path.join(gameDir, "index.html")));
    assert.match(player, /data-loading-progress/);
    assert.match(shell, /"mainPack":"game\.pck"/);
    assert.match(shell, /\.\.\/runtime\/game\.js/);
    assert.equal(fs.existsSync(path.join(gameDir, "game.wasm")), false);
  }
  assert.equal(manifest.games[0].slug, "starfall-protocol");
  assert.match(fs.readFileSync(path.join(playRoot, "player.js"), "utf8"), /status-progress/);
});
