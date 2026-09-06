import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

function walkFiles(root) {
  const files = [];
  function visit(directory) {
    const entries = fs.readdirSync(directory, { withFileTypes: true })
      .sort((left, right) => left.name.localeCompare(right.name));
    for (const entry of entries) {
      if (entry.name === ".gamephanes" || entry.name === ".godot") continue;
      const absolutePath = path.join(directory, entry.name);
      if (entry.isDirectory()) visit(absolutePath);
      else if (entry.isFile()) files.push(absolutePath);
    }
  }
  visit(root);
  return files;
}

export function copyProject(sourcePath, targetPath) {
  const source = path.resolve(sourcePath);
  const target = path.resolve(targetPath);
  fs.mkdirSync(target, { recursive: true });
  for (const entry of fs.readdirSync(source, { withFileTypes: true })) {
    const sourceEntry = path.join(source, entry.name);
    const targetEntry = path.join(target, entry.name);
    if (entry.isDirectory()) copyProject(sourceEntry, targetEntry);
    else if (entry.isFile()) fs.copyFileSync(sourceEntry, targetEntry);
  }
}

export function hashProject(projectPath) {
  const root = path.resolve(projectPath);
  const digest = crypto.createHash("sha256");
  for (const absolutePath of walkFiles(root)) {
    const relativePath = path.relative(root, absolutePath).replaceAll(path.sep, "/");
    digest.update(relativePath);
    digest.update("\0");
    digest.update(fs.readFileSync(absolutePath));
    digest.update("\0");
  }
  return digest.digest("hex");
}

function publicTaskContract(task) {
  return {
    schema_version: 1,
    task_id: task.id,
    title: task.title,
    instruction: task.description,
    taxonomy: task.taxonomy,
    requirements: task.requirements,
    runtime: { engine: "godot", version: "4.x", timeout_seconds: task.evaluation.timeout_seconds ?? 15 },
    evaluator: {
      visibility: task.registry?.evaluator_visibility ?? "local",
      contract: "The benchmark-owned evaluator runs after the agent submits the workspace.",
    },
  };
}

export function initializeWorkspace({ task, projectPath, workspacePath }) {
  const source = path.resolve(projectPath);
  const target = path.resolve(workspacePath);
  if (!fs.existsSync(source) || !fs.statSync(source).isDirectory()) {
    throw new Error(`project does not exist: ${source}`);
  }
  if (fs.existsSync(target)) {
    if (fs.readdirSync(target).length > 0) throw new Error(`workspace must be empty: ${target}`);
  } else {
    fs.mkdirSync(target, { recursive: true });
  }
  copyProject(source, target);
  const starterHash = hashProject(target);
  const metadataDirectory = path.join(target, ".gamephanes");
  fs.mkdirSync(metadataDirectory, { recursive: true });
  fs.writeFileSync(path.join(metadataDirectory, "instruction.json"), `${JSON.stringify(publicTaskContract(task), null, 2)}\n`);
  fs.writeFileSync(path.join(metadataDirectory, "workspace.json"), `${JSON.stringify({
    schema_version: 1,
    task_id: task.id,
    task_version: task.registry?.version ?? "local",
    starter_sha256: starterHash,
    created_at: new Date().toISOString(),
    evaluator_boundary: "Evaluator files are injected outside this workspace at evaluation time.",
  }, null, 2)}\n`);
  return { workspacePath: target, starterHash, instructionPath: path.join(metadataDirectory, "instruction.json") };
}
