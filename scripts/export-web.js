import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

import { findGodot } from "../src/godot/discovery.js";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outputRoot = path.join(root, "docs", "play");
const playerTemplate = fs.readFileSync(path.join(root, "scripts", "web-player.html"), "utf8");
const sharedRuntimeFiles = [
  "game.js",
  "game.wasm",
  "game.audio.worklet.js",
  "game.audio.position.worklet.js",
];

const games = [
  {
    slug: "starfall-protocol",
    title: "Starfall Protocol / 星坠协议",
    controls: { en: "WASD move, Shift dash, Space fire, E select", zh: "WASD 移动，Shift 冲刺，空格射击，E 选择" },
    touch: directionPad("Fire", "射击", "move_up", "move_down", "fire").concat([
      { actionName: "dash", code: "ShiftLeft", key: "Shift", label: "DASH", labelZh: "冲刺", ariaEn: "Dash", ariaZh: "冲刺", action: true },
      { actionName: "interact", code: "KeyE", key: "e", label: "SELECT", labelZh: "选择", ariaEn: "Select upgrade", ariaZh: "选择升级", action: true },
    ]),
  },
  {
    slug: "neon-relay",
    title: "Neon Relay",
    controls: { en: "A / D to move, Space to jump", zh: "A / D 移动，空格跳跃" },
    touch: [
      { actionName: "move_left", code: "KeyA", key: "a", label: "←", ariaEn: "Move left", ariaZh: "向左移动" },
      { actionName: "move_right", code: "KeyD", key: "d", label: "→", ariaEn: "Move right", ariaZh: "向右移动" },
      { actionName: "jump", code: "Space", key: " ", label: "JUMP", labelZh: "跳跃", ariaEn: "Jump", ariaZh: "跳跃", action: true },
    ],
  },
  {
    slug: "last-signal",
    title: "Last Signal",
    controls: { en: "WASD to move, Space to fire", zh: "WASD 移动，空格发射脉冲" },
    touch: directionPad("Fire", "脉冲", "move_up", "move_down", "fire"),
  },
  {
    slug: "gravity-lab",
    title: "Gravity Lab",
    controls: { en: "A / D to move, Space to flip gravity", zh: "A / D 移动，空格反转重力" },
    touch: [
      { actionName: "move_left", code: "KeyA", key: "a", label: "←", ariaEn: "Move left", ariaZh: "向左移动" },
      { actionName: "move_right", code: "KeyD", key: "d", label: "→", ariaEn: "Move right", ariaZh: "向右移动" },
      { actionName: "toggle_gravity", code: "Space", key: " ", label: "FLIP", labelZh: "反转", ariaEn: "Flip gravity", ariaZh: "反转重力", action: true },
    ],
  },
  {
    slug: "tiny-bastion",
    title: "Tiny Bastion",
    controls: { en: "B to build, Space to start the wave", zh: "B 建塔，空格开始波次" },
    touch: [
      { actionName: "build_tower", code: "KeyB", key: "b", label: "BUILD", labelZh: "建塔", ariaEn: "Build tower", ariaZh: "建造防御塔", action: true },
      { actionName: "start_wave", code: "Space", key: " ", label: "WAVE", labelZh: "开战", ariaEn: "Start wave", ariaZh: "开始波次", action: true },
    ],
  },
  {
    slug: "rift-arena",
    title: "Rift Arena",
    controls: { en: "WASD to move, Space to strike", zh: "WASD 移动，空格攻击" },
    touch: directionPad("Strike", "攻击", "move_forward", "move_back", "attack"),
  },
];

function directionPad(actionLabel, actionLabelZh, upAction, downAction, primaryAction) {
  return [
    { actionName: upAction, code: "KeyW", key: "w", label: "↑", ariaEn: "Move up", ariaZh: "向上移动" },
    { actionName: "move_left", code: "KeyA", key: "a", label: "←", ariaEn: "Move left", ariaZh: "向左移动" },
    { actionName: downAction, code: "KeyS", key: "s", label: "↓", ariaEn: "Move down", ariaZh: "向下移动" },
    { actionName: "move_right", code: "KeyD", key: "d", label: "→", ariaEn: "Move right", ariaZh: "向右移动" },
    { actionName: primaryAction, code: "Space", key: " ", label: actionLabel.toUpperCase(), labelZh: actionLabelZh, ariaEn: actionLabel, ariaZh: actionLabelZh, action: true },
  ];
}

function parseGodotArgument(argv) {
  const index = argv.indexOf("--godot");
  return index === -1 ? null : argv[index + 1];
}

function hash(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function escapeAttribute(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function renderPlayer(game) {
  return playerTemplate
    .replaceAll("{{TITLE}}", game.title)
    .replaceAll("{{CONTROLS_EN}}", escapeAttribute(game.controls.en))
    .replaceAll("{{CONTROLS_ZH}}", escapeAttribute(game.controls.zh))
    .replaceAll("{{TOUCH_CONTROLS}}", escapeAttribute(JSON.stringify(game.touch)));
}

function rewriteGameShell(gameHtml, packSize, wasmSize) {
  const original = fs.readFileSync(gameHtml, "utf8");
  const rewritten = original
    .replace('src="game.js"', 'src="../runtime/game.js"')
    .replace('"executable":"game"', '"executable":"../runtime/game","mainPack":"game.pck"')
    .replace(`"fileSizes":{"game.pck":${packSize},"game.wasm":${wasmSize}}`, `"fileSizes":{"game.pck":${packSize},"../runtime/game.wasm":${wasmSize}}`);

  if (rewritten === original || !rewritten.includes('"mainPack":"game.pck"')) {
    throw new Error(`Could not rewrite generated shell: ${gameHtml}`);
  }
  fs.writeFileSync(gameHtml, rewritten);
}

const godot = findGodot(parseGodotArgument(process.argv.slice(2)));
if (!godot) {
  console.error("Godot was not found. Set GAMEPHANES_GODOT or pass --godot <path>.");
  process.exit(1);
}

fs.rmSync(outputRoot, { recursive: true, force: true });
fs.mkdirSync(path.join(outputRoot, "runtime"), { recursive: true });
fs.copyFileSync(path.join(root, "scripts", "web-player.css"), path.join(outputRoot, "player.css"));
fs.copyFileSync(path.join(root, "scripts", "web-player.js"), path.join(outputRoot, "player.js"));

const manifest = { games: [] };
for (const game of games) {
  const projectDir = path.join(root, "examples", game.slug);
  const gameDir = path.join(outputRoot, game.slug);
  const gameHtml = path.join(gameDir, "game.html");
  fs.mkdirSync(gameDir, { recursive: true });

  console.log(`Exporting ${game.title}...`);
  const result = spawnSync(godot, ["--headless", "--path", projectDir, "--export-release", "Web", gameHtml], {
    cwd: root,
    stdio: "inherit",
  });
  if (result.status !== 0) process.exit(result.status ?? 1);

  for (const filename of sharedRuntimeFiles) {
    const exported = path.join(gameDir, filename);
    const shared = path.join(outputRoot, "runtime", filename);
    if (!fs.existsSync(shared)) {
      fs.copyFileSync(exported, shared);
    } else if (hash(exported) !== hash(shared)) {
      throw new Error(`The Web runtime differs for ${game.title}: ${filename}`);
    }
    fs.rmSync(exported);
  }

  const packPath = path.join(gameDir, "game.pck");
  const wasmPath = path.join(outputRoot, "runtime", "game.wasm");
  rewriteGameShell(gameHtml, fs.statSync(packPath).size, fs.statSync(wasmPath).size);
  fs.writeFileSync(path.join(gameDir, "index.html"), renderPlayer(game));
  manifest.games.push({ slug: game.slug, title: game.title, path: `./${game.slug}/`, pack_bytes: fs.statSync(packPath).size });
}

fs.writeFileSync(path.join(outputRoot, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
console.log(`Exported ${games.length} games to ${path.relative(root, outputRoot)}.`);
