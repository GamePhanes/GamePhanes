import fs from "node:fs";
import path from "node:path";

function executableNames() {
  return process.platform === "win32"
    ? ["godot.exe", "godot4.exe", "Godot_v4.6-stable_win64_console.exe", "Godot_v4.5.1-stable_win64_console.exe"]
    : ["godot", "godot4"];
}

export function findGodot(explicitPath, env = process.env) {
  const candidates = [];
  if (explicitPath) candidates.push(path.resolve(explicitPath));
  if (env.GAMEBUDDY_GODOT) candidates.push(path.resolve(env.GAMEBUDDY_GODOT));

  const pathEntries = (env.PATH ?? "").split(path.delimiter).filter(Boolean);
  for (const entry of pathEntries) {
    for (const name of executableNames()) candidates.push(path.join(entry, name));
  }

  return candidates.find((candidate) => {
    try {
      return fs.statSync(candidate).isFile();
    } catch {
      return false;
    }
  }) ?? null;
}
