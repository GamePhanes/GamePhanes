import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadTask } from "../src/core/task.js";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const tasksDirectory = path.join(projectRoot, "benchmark", "tasks");
const docsDirectory = path.join(projectRoot, "docs");
const registryDirectory = path.join(docsDirectory, "registry");
const preferredOrder = [
  "starfall-protocol",
  "neon-relay",
  "repair-neon-relay-jump",
  "last-signal",
  "gravity-lab",
  "tiny-bastion",
  "rift-arena",
  "platformer-basic",
];

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function label(value) {
  return value.replaceAll("_", " ").replace(/\b\w/g, (character) => character.toUpperCase());
}

function taskFileUrl(fileName) {
  return `https://github.com/GamePhanes/GamePhanes/blob/main/benchmark/tasks/${fileName}`;
}

function projectUrl(task) {
  const projectName = path.basename(task.project.path);
  return `https://github.com/GamePhanes/GamePhanes/tree/main/examples/${projectName}`;
}

function taskCommand(fileName) {
  return `node ./bin/gamephanes.js run ./benchmark/tasks/${fileName} \\` + "\n  --godot /path/to/godot";
}

function renderBadges(task) {
  const kindLabel = task.registry.kind === "coding_challenge" ? "Coding challenge" : "Reference environment";
  const visibilityLabel = task.registry.evaluator_visibility === "public_development"
    ? "Public development"
    : task.registry.evaluator_visibility === "sealed" ? "Sealed evaluator" : "Public evaluator";
  return `<div class="registry-badges">
      <span>${escapeHtml(label(task.taxonomy.domain))}</span>
      <span>${escapeHtml(label(task.taxonomy.subdomain))}</span>
      <span>${escapeHtml(kindLabel)}</span>
      <span>${escapeHtml(visibilityLabel)}</span>
      <span>${escapeHtml(task.registry.difficulty)}</span>
    </div>`;
}

function renderCard(entry, hrefPrefix = "") {
  const { task, fileName } = entry;
  const tags = task.registry.tags.map((tag) => `<span>${escapeHtml(tag)}</span>`).join("");
  return `<article class="registry-card">
    <div class="registry-card-topline">
      <h3><a href="${hrefPrefix}${escapeHtml(task.registry.slug)}/">${escapeHtml(task.title)}</a></h3>
      <div class="registry-card-actions">
        <button type="button" data-copy-text="${escapeHtml(task.id)}" aria-label="Copy task ID" title="Copy task ID">Copy ID</button>
        <a href="${taskFileUrl(fileName)}">GitHub</a>
      </div>
    </div>
    ${renderBadges(task)}
    <p>${escapeHtml(task.description)}</p>
    <div class="registry-card-footer">
      <div class="registry-tags">${tags}</div>
      <small>Created by ${escapeHtml(task.registry.author)}</small>
    </div>
  </article>`;
}

function renderHeader(homePrefix) {
  return `<header class="site-header registry-site-header">
    <a class="brand" href="${homePrefix}" aria-label="GamePhanes home">
      <span class="brand-mark" aria-hidden="true">GP</span>
      <span>GamePhanes</span>
    </a>
    <nav aria-label="Primary navigation">
      <a href="${homePrefix}registry/">Registry</a>
      <a href="${homePrefix}#taxonomy">Taxonomy</a>
      <a href="${homePrefix}architecture.md">Architecture</a>
      <a class="nav-action" href="https://github.com/GamePhanes/GamePhanes">GitHub</a>
    </nav>
  </header>`;
}

function renderRegistryIndex(entries) {
  const cards = entries.map((entry) => renderCard(entry)).join("\n");
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Browse public GamePhanes task environments for interactive software coding agents.">
    <title>Registry - GamePhanes</title>
    <link rel="icon" href="../assets/favicon.svg" type="image/svg+xml">
    <link rel="stylesheet" href="../styles.css">
  </head>
  <body class="registry-page">
    ${renderHeader("../")}
    <main>
      <section class="registry-index-heading">
        <div class="section-inner">
          <p class="section-kicker">Task registry</p>
          <div class="registry-heading-layout">
            <h1>Public task environments</h1>
            <p>Each entry is a concrete, runnable task contract. The current catalog contains open reference environments; sealed coding challenges will use the same page structure with hidden evaluators.</p>
          </div>
      <div class="registry-release"><strong>gamephanes-public==0.1</strong><span>${entries.length} published task entries</span></div>
        </div>
      </section>
      <section class="registry-catalog" aria-label="Public task environments">
        <div class="registry-grid">${cards}</div>
      </section>
    </main>
    <footer><div class="section-inner footer-inner"><span>GamePhanes</span><span>Terminal-Bench for interactive software coding agents.</span><span data-copyright></span></div></footer>
    <script src="../registry.js"></script>
  </body>
</html>
`;
}

function renderTaskDetail(entry) {
  const { task, fileName } = entry;
  const requirements = task.requirements
    .map((requirement) => `<li><strong>${escapeHtml(requirement.id)}</strong><span>${escapeHtml(requirement.description)}</span></li>`)
    .join("\n");
  const tags = task.registry.tags.map((tag) => `<span>${escapeHtml(tag)}</span>`).join("");
  const command = taskCommand(fileName);
  const demoAction = task.registry.play_path
    ? `<a class="button button-primary" href="../../${escapeHtml(task.registry.play_path)}">Play environment</a>`
    : `<a class="button button-primary" href="${projectUrl(task)}">View project</a>`;
  const timeout = task.evaluation.timeout_seconds ?? 15;
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="${escapeHtml(task.description)}">
    <title>${escapeHtml(task.title)} - GamePhanes Registry</title>
    <link rel="icon" href="../../assets/favicon.svg" type="image/svg+xml">
    <link rel="stylesheet" href="../../styles.css">
  </head>
  <body class="registry-page">
    ${renderHeader("../../")}
    <main class="task-detail">
      <nav class="breadcrumbs" aria-label="Breadcrumb">
        <a href="../../">Home</a><span>/</span><a href="../">Registry</a><span>/</span><strong>${escapeHtml(task.registry.slug)}</strong>
      </nav>
      <header class="task-detail-header">
        <h1>${escapeHtml(task.title)}</h1>
        <div class="task-version">${escapeHtml(task.registry.version)}</div>
        <div class="task-source-links">
          <a href="${taskFileUrl(fileName)}">Task JSON</a>
          <a href="${projectUrl(task)}">Project source</a>
          <button type="button" data-copy-text="${escapeHtml(task.id)}">Copy task ID</button>
        </div>
        ${renderBadges(task)}
      </header>

      <section class="task-detail-section" aria-labelledby="usage-title">
        <h2 id="usage-title">Usage</h2>
        <div class="task-command">
          <pre><code>${escapeHtml(command)}</code></pre>
          <button type="button" data-copy-text="${escapeHtml(command)}">Copy command</button>
        </div>
      </section>

      <section class="task-detail-section" aria-labelledby="demo-title">
        <h2 id="demo-title">Runtime evidence</h2>
        <div class="task-evidence">
          <img src="../../assets/${escapeHtml(task.registry.image)}" alt="${escapeHtml(task.title)} runtime capture">
          <div>
            <p>${task.registry.kind === "coding_challenge"
    ? "This is a deliberately damaged starter project. The Coding Agent must diagnose and repair it through terminal commands and project edits; evaluator-controlled inputs probe the result."
    : "This executable Godot project is the feedback surface for the task. Evaluator-controlled inputs probe the candidate project; the Coding Agent acts through terminal commands and code changes."}</p>
            ${demoAction}
          </div>
        </div>
      </section>

      <section class="task-detail-section task-instruction" aria-labelledby="instruction-title">
        <h2 id="instruction-title">Instruction</h2>
        <p>${escapeHtml(task.description)}</p>
        <h3>Success criteria</h3>
        <ul>${requirements}</ul>
      </section>

      <section class="task-detail-section" aria-labelledby="evaluation-title">
        <h2 id="evaluation-title">Evaluation contract</h2>
        <dl class="task-facts">
          <div><dt>Task ID</dt><dd>${escapeHtml(task.id)}</dd></div>
          <div><dt>Runtime</dt><dd>Godot 4.x</dd></div>
          <div><dt>Timeout</dt><dd>${timeout} seconds</dd></div>
          <div><dt>Assertions</dt><dd>${task.evaluation.assertions.length} deterministic checks</dd></div>
          <div><dt>Harness</dt><dd>External, benchmark-owned</dd></div>
          <div><dt>Agent action</dt><dd>Terminal commands and project edits</dd></div>
        </dl>
      </section>

      <section class="task-detail-section" aria-labelledby="tags-title">
        <h2 id="tags-title">Tags</h2>
        <div class="registry-tags task-tags">${tags}</div>
        <p class="task-author">Created by ${escapeHtml(task.registry.author)}</p>
      </section>

      <p class="reference-notice">${task.registry.kind === "coding_challenge"
    ? "PUBLIC DEVELOPMENT CHALLENGE. THE EVALUATOR IS VISIBLE FOR AUTHORING AND INTEGRATION; THIS ENTRY IS NOT A SEALED BENCHMARK SCORE."
    : "PUBLIC REFERENCE ENVIRONMENT. THIS PAGE DOCUMENTS THE OPEN CONTRACT; SEALED STARTERS, HIDDEN ASSERTIONS, AND PRODUCTION ROLLOUTS ARE NOT PUBLISHED HERE."}</p>
    </main>
    <footer><div class="section-inner footer-inner"><span>GamePhanes</span><span>Terminal-Bench for interactive software coding agents.</span><span data-copyright></span></div></footer>
    <script src="../../registry.js"></script>
  </body>
</html>
`;
}

const entries = fs.readdirSync(tasksDirectory)
  .filter((fileName) => fileName.endsWith(".json"))
  .map((fileName) => ({ fileName, task: loadTask(path.join(tasksDirectory, fileName)).task }))
  .filter(({ task }) => task.registry)
  .sort((left, right) => preferredOrder.indexOf(left.task.registry.slug) - preferredOrder.indexOf(right.task.registry.slug));

const slugs = new Set();
for (const { task } of entries) {
  if (slugs.has(task.registry.slug)) throw new Error(`duplicate registry slug: ${task.registry.slug}`);
  slugs.add(task.registry.slug);
  const imagePath = path.join(docsDirectory, "assets", task.registry.image);
  if (!fs.existsSync(imagePath)) throw new Error(`registry image does not exist: ${imagePath}`);
  if (task.registry.play_path && !fs.existsSync(path.join(docsDirectory, task.registry.play_path))) {
    throw new Error(`registry play path does not exist: ${task.registry.play_path}`);
  }
}

fs.rmSync(registryDirectory, { recursive: true, force: true });
fs.mkdirSync(registryDirectory, { recursive: true });
fs.writeFileSync(path.join(registryDirectory, "index.html"), renderRegistryIndex(entries));
for (const entry of entries) {
  const detailDirectory = path.join(registryDirectory, entry.task.registry.slug);
  fs.mkdirSync(detailDirectory, { recursive: true });
  fs.writeFileSync(path.join(detailDirectory, "index.html"), renderTaskDetail(entry));
}

console.log(`Built ${entries.length} registry task pages in ${registryDirectory}`);
