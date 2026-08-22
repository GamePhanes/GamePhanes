export const TASK_TAXONOMY = Object.freeze({
  gameplay_systems: Object.freeze([
    "movement",
    "combat",
    "physics",
    "ai_navigation",
    "progression_economy",
  ]),
  engine_runtime: Object.freeze([
    "scene_lifecycle",
    "engine_apis",
    "state_signals",
    "performance",
    "platform_compatibility",
  ]),
  ui_interaction: Object.freeze([
    "input_controls",
    "hud_menus",
    "camera_feedback",
    "accessibility",
  ]),
  content_design: Object.freeze([
    "level_design",
    "procedural_content",
    "asset_integration",
    "narrative_dialogue",
    "audio_integration",
  ]),
  architecture_data: Object.freeze([
    "scenes_resources",
    "save_load",
    "data_driven_systems",
    "modularity_dependencies",
  ]),
  delivery_quality: Object.freeze([
    "regression_safety",
    "tests_instrumentation",
    "build_packaging",
  ]),
});

export const TASK_TYPES = Object.freeze([
  "reference_environment",
  "bug_fix",
  "feature_implementation",
  "runtime_debugging",
  "interaction_repair",
  "regression_repair",
  "design_completion",
  "performance_optimization",
  "build_delivery",
]);

export const TARGET_TASK_MIX = Object.freeze({
  gameplay_systems: Object.freeze({
    movement: 6,
    combat: 6,
    physics: 5,
    ai_navigation: 5,
    progression_economy: 6,
  }),
  engine_runtime: Object.freeze({
    scene_lifecycle: 6,
    engine_apis: 5,
    state_signals: 4,
    performance: 4,
    platform_compatibility: 3,
  }),
  ui_interaction: Object.freeze({
    input_controls: 5,
    hud_menus: 4,
    camera_feedback: 4,
    accessibility: 3,
  }),
  content_design: Object.freeze({
    level_design: 4,
    procedural_content: 3,
    asset_integration: 3,
    narrative_dialogue: 2,
    audio_integration: 2,
  }),
  architecture_data: Object.freeze({
    scenes_resources: 4,
    save_load: 3,
    data_driven_systems: 3,
    modularity_dependencies: 2,
  }),
  delivery_quality: Object.freeze({
    regression_safety: 3,
    tests_instrumentation: 3,
    build_packaging: 2,
  }),
});

export function validateTaskTaxonomy(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw new Error("taxonomy must be an object");
  }
  const subdomains = TASK_TAXONOMY[input.domain];
  if (!subdomains) throw new Error("taxonomy.domain is not supported");
  if (!subdomains.includes(input.subdomain)) {
    throw new Error(`taxonomy.subdomain is not supported for ${input.domain}`);
  }
  if (!TASK_TYPES.includes(input.task_type)) throw new Error("taxonomy.task_type is not supported");
  return input;
}
