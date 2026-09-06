import fs from "node:fs";
import path from "node:path";

const SOURCES = new Set(["procedural", "curated", "generated", "adapted", "user"]);
const TYPES = new Set(["character_2d", "spritesheet", "texture_2d", "model_3d", "audio", "font", "ui", "procedural"]);

function requireString(value, field) {
  if (typeof value !== "string" || value.trim() === "") {
    throw new Error(`${field} must be a non-empty string`);
  }
  return value;
}

function requireObject(value, field) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${field} must be an object`);
  }
  return value;
}

function isInside(root, candidate) {
  const relative = path.relative(root, candidate);
  return relative === "" || (relative !== ".." && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative));
}

export function validateManifest(input, baseDirectory = process.cwd(), options = {}) {
  requireObject(input, "manifest");
  if (input.schema_version !== 1) throw new Error("schema_version must be 1");
  requireString(input.id, "id");
  if (!Array.isArray(input.assets) || input.assets.length === 0) {
    throw new Error("assets must be a non-empty array");
  }

  const ids = new Set();
  const root = path.resolve(baseDirectory);
  const missingFiles = [];
  const assets = input.assets.map((asset, index) => {
    const prefix = `assets[${index}]`;
    requireObject(asset, prefix);
    const id = requireString(asset.id, `${prefix}.id`);
    if (ids.has(id)) throw new Error(`${prefix}.id must be unique`);
    ids.add(id);

    const type = requireString(asset.type, `${prefix}.type`);
    if (!TYPES.has(type)) throw new Error(`${prefix}.type is not supported: ${type}`);
    const source = requireString(asset.source, `${prefix}.source`);
    if (!SOURCES.has(source)) throw new Error(`${prefix}.source is not supported: ${source}`);
    requireString(asset.license, `${prefix}.license`);

    const files = asset.files ?? [];
    if (!Array.isArray(files)) throw new Error(`${prefix}.files must be an array`);
    const resolvedFiles = files.map((file, fileIndex) => {
      requireString(file, `${prefix}.files[${fileIndex}]`);
      const resolved = path.resolve(root, file);
      if (!isInside(root, resolved)) throw new Error(`${prefix}.files[${fileIndex}] escapes manifest directory`);
      if (options.checkFiles !== false && !fs.existsSync(resolved)) missingFiles.push(file);
      return file;
    });

    if (source === "procedural" && resolvedFiles.length > 0) {
      throw new Error(`${prefix}.files must be empty for procedural assets`);
    }
    if (source !== "procedural" && resolvedFiles.length === 0) {
      throw new Error(`${prefix}.files must contain at least one file for ${source} assets`);
    }

    const metadata = asset.metadata ?? {};
    requireObject(metadata, `${prefix}.metadata`);
    return { ...asset, files: resolvedFiles, metadata };
  });

  if (missingFiles.length > 0) {
    throw new Error(`manifest references missing files: ${missingFiles.join(", ")}`);
  }
  return { ...input, assets };
}

export function loadManifest(manifestPath, options = {}) {
  const absolutePath = path.resolve(manifestPath);
  let parsed;
  try {
    parsed = JSON.parse(fs.readFileSync(absolutePath, "utf8"));
  } catch (error) {
    throw new Error(`cannot read asset manifest ${absolutePath}: ${error.message}`);
  }
  return {
    manifest: validateManifest(parsed, path.dirname(absolutePath), options),
    manifestPath: absolutePath,
    manifestDirectory: path.dirname(absolutePath),
  };
}
