import { createServer } from "node:http";
import { createReadStream, createWriteStream, existsSync } from "node:fs";
import { mkdir, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import { basename, extname, join, normalize, resolve } from "node:path";
import { randomUUID, timingSafeEqual } from "node:crypto";
import { spawn } from "node:child_process";

const port = Number(process.env.PORT ?? 3100);
const host = process.env.HOST ?? "127.0.0.1";
const root = resolve(process.env.GAMEPHANES_ROOT ?? "/home/shuaiqi/GamePhanes");
const jobsRoot = resolve(process.env.JOBS_ROOT ?? "/home/shuaiqi/game-oj-data/jobs");
const image = process.env.EVALUATOR_IMAGE ?? "game-terminal-bench-repair-neon-relay-jump";
const adminPassword = process.env.OJ_ADMIN_PASSWORD ?? "";
const task = {
  id: "repair-neon-relay-jump",
  title: "Repair Neon Relay Jump",
  description: "Repair the Godot phase jump without breaking shard collection or relay completion.",
  tests: join(root, "benchmark/harbor-tasks/repair-neon-relay-jump/tests"),
};
const maxUploadBytes = 12 * 1024 * 1024;
const maxLogBytes = 1024 * 1024;

await mkdir(jobsRoot, { recursive: true, mode: 0o700 });

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
  response.end(JSON.stringify(body));
}

function sendText(response, statusCode, body) {
  response.writeHead(statusCode, { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" });
  response.end(body);
}

function adminAuthorized(request) {
  const supplied = request.headers["x-admin-password"] ?? "";
  const expected = Buffer.from(adminPassword);
  const received = Buffer.from(supplied);
  return expected.length > 0 && expected.length === received.length && timingSafeEqual(expected, received);
}

async function loadJob(id) {
  if (!/^[0-9a-f-]{36}$/.test(id)) return null;
  try {
    return JSON.parse(await readFile(join(jobsRoot, id, "job.json"), "utf8"));
  } catch {
    return null;
  }
}

async function saveJob(job) {
  await writeFile(join(jobsRoot, job.id, "job.json"), JSON.stringify(job, null, 2), { mode: 0o600 });
}

async function readProjectFiles(directory, prefix = "") {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const relative = join(prefix, entry.name);
    const absolute = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...await readProjectFiles(absolute, relative));
    else if (entry.isFile() && /\.(gd|tscn|godot|md|txt|json)$/.test(entry.name) && files.length < 40) {
      const info = await stat(absolute);
      if (info.size <= 100_000) files.push({ path: relative, content: await readFile(absolute, "utf8") });
    }
  }
  return files;
}

function run(command, args, options = {}) {
  return new Promise((resolveRun) => {
    const child = spawn(command, args, { ...options, stdio: ["ignore", "pipe", "pipe"] });
    let output = "";
    const append = (chunk) => {
      if (Buffer.byteLength(output) < maxLogBytes) output += chunk.toString();
    };
    child.stdout.on("data", append);
    child.stderr.on("data", append);
    const timer = setTimeout(() => child.kill("SIGTERM"), 125_000);
    child.on("close", (code, signal) => {
      clearTimeout(timer);
      resolveRun({ code, signal, output });
    });
    child.on("error", (error) => {
      clearTimeout(timer);
      resolveRun({ code: -1, signal: null, output: `${error.message}\n` });
    });
  });
}

async function evaluate(job) {
  const directory = join(jobsRoot, job.id);
  const taskRoot = join(directory, "task");
  job.status = "preparing";
  await saveJob(job);

  const extraction = await run("python3", [join(process.cwd(), "scripts/safe_extract.py"), join(directory, "submission.zip"), taskRoot]);
  const required = ["task.toml", "instruction.md", "environment/Dockerfile", "environment/project/project.godot", "tests/test.sh", "solution/solve.sh"];
  const missing = required.filter((file) => !existsSync(join(taskRoot, file)));
  if (extraction.code !== 0 || missing.length > 0) {
    job.status = "rejected";
    job.log = `${extraction.output}\nMissing required task files: ${missing.join(", ")}\n`;
    await saveJob(job);
    return;
  }
  job.status = "running";
  await saveJob(job);
  const imageTag = `game-oj-task-${job.id}`;
  const environment = join(taskRoot, "environment");
  const tests = join(taskRoot, "tests");
  const solution = join(taskRoot, "solution");
  const build = await run("docker", ["build", "--pull=false", "--build-arg", "HTTP_PROXY=http://172.17.0.1:17892", "--build-arg", "HTTPS_PROXY=http://172.17.0.1:17892", "-t", imageTag, environment], { env: { ...process.env, DOCKER_BUILDKIT: "0" } });
  if (build.code !== 0) {
    job.status = "rejected";
    job.log = `Environment build failed.\n${build.output}`;
    await saveJob(job);
    return;
  }
  const sandbox = ["run", "--rm", "--network", "none", "--read-only", "--cap-drop", "ALL", "--pids-limit", "1024", "--memory", "2g", "--cpus", "1", "--tmpfs", "/tmp:rw,noexec,nosuid,size=256m", "--tmpfs", "/logs:rw,nosuid,size=64m", "-e", "HOME=/tmp"];
  const broken = await run("docker", [...sandbox, "-v", `${join(environment, "project")}:/app:ro`, "-v", `${tests}:/tests:ro`, imageTag, "bash", "/tests/test.sh"]);
  const candidate = join(directory, "candidate-project");
  await run("cp", ["-a", join(environment, "project"), candidate]);
  await run("chmod", ["-R", "a+rwX", candidate]);
  const solved = await run("docker", [...sandbox, "-v", `${candidate}:/app`, "-v", `${tests}:/tests:ro`, "-v", `${solution}:/solution:ro`, imageTag, "bash", "-lc", "bash /solution/solve.sh && bash /tests/test.sh"]);
  await run("rm", ["-rf", candidate]);
  await run("docker", ["image", "rm", "-f", imageTag]);
  job.status = "pending_review";
  job.validation = { originalProblemDetected: broken.code !== 0, solutionPasses: solved.code === 0 };
  job.log = `Original verification exit: ${broken.code}\nSolution verification exit: ${solved.code}\n\n--- Original verifier ---\n${broken.output}\n--- Solution verifier ---\n${solved.output}`;
  await saveJob(job);
}

async function receiveZip(request, destination) {
  let bytes = 0;
  const output = createWriteStream(destination, { mode: 0o600 });
  try {
    for await (const chunk of request) {
      bytes += chunk.length;
      if (bytes > maxUploadBytes) throw new Error("ZIP exceeds the 12 MB upload limit");
      if (!output.write(chunk)) await new Promise((done) => output.once("drain", done));
    }
  } finally {
    output.end();
  }
  if (bytes === 0) throw new Error("empty upload");
}

function serveStatic(request, response) {
  const requested = request.url === "/" ? "index.html" : basename(normalize(request.url));
  const file = join(process.cwd(), "public", requested);
  if (!existsSync(file)) return sendText(response, 404, "Not found\n");
  response.writeHead(200, {
    "content-type": extname(file) === ".js" ? "text/javascript; charset=utf-8" : "text/html; charset=utf-8",
    "cache-control": "no-store",
  });
  createReadStream(file).pipe(response);
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url, `http://${request.headers.host ?? "localhost"}`);
  if (request.method === "GET" && url.pathname === "/api/tasks") return sendJson(response, 200, [{ id: task.id, title: task.title, description: task.description }]);

  if (request.method === "GET" && /^\/api\/submissions\/[0-9a-f-]{36}$/.test(url.pathname)) {
    const job = await loadJob(url.pathname.split("/").pop());
    return job ? sendJson(response, 200, job) : sendJson(response, 404, { error: "submission not found" });
  }

  if (request.method === "GET" && url.pathname === "/api/admin/submissions") {
    if (!adminAuthorized(request)) return sendJson(response, 401, { error: "administrator password required" });
    const entries = await readdir(jobsRoot, { withFileTypes: true });
    const jobs = await Promise.all(entries.filter((entry) => entry.isDirectory()).map((entry) => loadJob(entry.name)));
    return sendJson(response, 200, jobs.filter(Boolean).sort((a, b) => b.createdAt.localeCompare(a.createdAt)));
  }

  if (request.method === "GET" && /^\/api\/admin\/submissions\/[0-9a-f-]{36}\/source$/.test(url.pathname)) {
    if (!adminAuthorized(request)) return sendJson(response, 401, { error: "administrator password required" });
    const id = url.pathname.split("/")[4];
    const job = await loadJob(id);
    if (!job) return sendJson(response, 404, { error: "submission not found" });
    return sendJson(response, 200, { id, files: await readProjectFiles(join(jobsRoot, id, "task")) });
  }

  if (request.method === "GET" && /^\/api\/admin\/submissions\/[0-9a-f-]{36}\/archive$/.test(url.pathname)) {
    if (!adminAuthorized(request)) return sendJson(response, 401, { error: "administrator password required" });
    const id = url.pathname.split("/")[4];
    const archive = join(jobsRoot, id, "submission.zip");
    if (!existsSync(archive)) return sendJson(response, 404, { error: "submission archive not found" });
    response.writeHead(200, {
      "content-type": "application/zip",
      "content-disposition": `attachment; filename="${id}.zip"`,
      "cache-control": "no-store",
    });
    return createReadStream(archive).pipe(response);
  }

  if (request.method === "POST" && /^\/api\/admin\/submissions\/[0-9a-f-]{36}\/review$/.test(url.pathname)) {
    if (!adminAuthorized(request)) return sendJson(response, 401, { error: "administrator password required" });
    const id = url.pathname.split("/")[4];
    const job = await loadJob(id);
    if (!job) return sendJson(response, 404, { error: "submission not found" });
    let body = "";
    for await (const chunk of request) body += chunk;
    try {
      const review = JSON.parse(body);
      if (!["approved", "rejected", "changes_requested"].includes(review.decision)) throw new Error("invalid decision");
      job.status = review.decision;
      job.review = { decision: review.decision, score: Number(review.score) || 0, comment: String(review.comment ?? "").slice(0, 4000), reviewedAt: new Date().toISOString() };
      await saveJob(job);
      return sendJson(response, 200, job);
    } catch (error) { return sendJson(response, 400, { error: error.message }); }
  }

  if (request.method === "POST" && url.pathname === "/api/submissions") {
    if (url.searchParams.get("task") !== task.id || request.headers["content-type"] !== "application/zip") {
      return sendJson(response, 400, { error: "send an application/zip task package with task=repair-neon-relay-jump" });
    }
    const id = randomUUID();
    const directory = join(jobsRoot, id);
    const job = { id, task: task.id, status: "queued", createdAt: new Date().toISOString(), exitCode: null, log: "" };
    await mkdir(directory, { recursive: true, mode: 0o700 });
    try {
      await receiveZip(request, join(directory, "submission.zip"));
      await saveJob(job);
      void evaluate(job);
      return sendJson(response, 202, { id, status: job.status });
    } catch (error) {
      await rm(directory, { recursive: true, force: true });
      return sendJson(response, 400, { error: error.message });
    }
  }

  if (request.method === "GET") return serveStatic(request, response);
  return sendJson(response, 404, { error: "not found" });
});

server.listen(port, host, () => console.log(`Game OJ listening on http://${host}:${port}`));
