const translations = {
  en: {
    navWorkflow: "Workflow",
    navShowcase: "Showcase",
    navBenchmark: "Benchmark",
    navArchitecture: "Architecture",
    heroImageAlt: "Starfall Protocol running inside the GamePhanes playtest environment",
    heroEyebrow: "Game coding agent infrastructure",
    heroStatement: "Evaluate behavior. Capture rollouts.",
    heroCopy: "Godot-first evaluation infrastructure for game coding agents, designed for private tasks, hidden grading, and training-ready repair trajectories.",
    viewGithub: "View on GitHub",
    seeBenchmark: "See the benchmark",
    runLabel: "Latest public demo run",
    latestRun: "LATEST PUBLIC DEMO",
    buildPass: "BUILD PASS",
    runtimePass: "RUNTIME PASS",
    scoreLabel: " SCORE",
    proofKicker: "Evidence over claims",
    proofTitle: "A game is not done when the code looks right.",
    proofLead: "GamePhanes launches the project, performs real inputs, observes runtime state, and checks deterministic assertions before reporting success.",
    metricAssertions: "Assertions passed",
    metricSlices: "Playable slices",
    metricErrors: "Protocol errors",
    metricScore: "Functional score",
    showcaseKicker: "One golden demo. Five reference surfaces.",
    showcaseTitle: "Not mockups. Running Godot projects.",
    showcaseLead: "Each slice has a distinct art direction, playable loop, external harness, and deterministic score.",
    starfallGenre: "Golden demo · action vertical slice",
    starfallCopy: "Survive the drone encounter, choose a protocol, and defeat the Oracle in an original 8–12 minute Godot slice.",
    neonGenre: "Momentum platformer",
    neonCopy: "Sprint through an electric skyline, phase-jump, and chain three energy shards into the relay.",
    signalGenre: "Tactical survival",
    signalCopy: "Reposition a field transmitter and burn threats from a living radio map.",
    gravityGenre: "Physics puzzle",
    gravityCopy: "Reverse polarity, stabilize an energy core, and unlock the sealed chamber.",
    bastionGenre: "Micro tower defense",
    bastionCopy: "Spend carefully, place two towers, and hold the miniature keep until dawn.",
    riftGenre: "3D arena combat",
    riftCopy: "Enter a low-poly breach, strike its warden, and stabilize the dimensional ring.",
    playNow: "Play now",
    viewProject: "View project",
    showcaseVerified: "ALL VERIFIED",
    workflowLabel: "GamePhanes workflow",
    workflowKicker: "Closed-loop engineering",
    workflowTitle: "From intent to verified behavior.",
    workflowUnderstand: "Understand",
    workflowRequirements: "Requirements",
    workflowBuild: "Build",
    workflowProject: "Godot project",
    workflowRun: "Run",
    workflowHeadless: "Headless engine",
    workflowPlay: "Play",
    workflowInputs: "Real inputs",
    workflowObserve: "Observe",
    workflowState: "State + logs",
    workflowRepair: "Repair",
    workflowEvidence: "Evidence-guided",
    systemsKicker: "Designed for agents",
    systemsTitle: "Run the artifact. Test the interaction. Score the behavior.",
    systemSandboxTitle: "Sandboxed project copies",
    systemSandboxCopy: "Every evaluation runs against a temporary copy, leaving the original candidate project unchanged.",
    systemHarnessTitle: "External playtest harnesses",
    systemHarnessCopy: "Benchmark-owned drivers load the game, perform actions, and emit structured runtime evidence.",
    systemAssertionsTitle: "Deterministic assertions",
    systemAssertionsCopy: "Movement, velocity, score, health, and other state can be evaluated without an opaque model judge.",
    systemHiddenTitle: "Hidden evaluation direction",
    systemHiddenCopy: "Private task variants and benchmark-owned evaluators will measure generalization without exposing answers.",
    systemRolloutTitle: "Rollout data direction",
    systemRolloutCopy: "Actions, patches, runtime evidence, failures, and costs form training-ready repair trajectories.",
    assetsPipelineLabel: "GamePhanes asset pipeline",
    assetsKicker: "Asset engineering",
    assetsTitle: "Assets need contracts, not just prompts.",
    assetsLead: "Every asset can carry its source, license, files, and runtime metadata before an Agent places it in a scene.",
    assetsSpec: "AssetSpec",
    assetsManifest: "Manifest",
    assetsNormalize: "Normalize",
    assetsValidate: "Validate",
    reportKicker: "Machine-readable proof",
    reportTitle: "Every run ends with a report.",
    reportLead: "Store it, compare it, or use failures as the next repair prompt.",
    roadmapKicker: "Roadmap",
    roadmapTitle: "From public contract to private evaluation.",
    milestoneEnvironment: "Environment",
    milestoneNow: "Available now",
    milestoneAgent: "GamePhanes-Bench",
    milestoneRepair: "Agent baselines",
    milestonePlaytest: "Rich observation",
    milestoneVision: "Vision + state",
    milestoneHidden: "Hidden evaluation",
    milestoneTasks: "Private task variants",
    closingKicker: "Open contract. Hidden evaluation. Better agents.",
    closingTitle: "Build the evaluation layer for interactive software.",
    closingButton: "Explore GamePhanes on GitHub",
    footerTagline: "Evaluation and rollout infrastructure for game coding agents."
  },
  zh: {
    navWorkflow: "工作流",
    navShowcase: "游戏展示",
    navBenchmark: "评测基准",
    navArchitecture: "架构",
    heroImageAlt: "GamePhanes Playtest 环境中运行的 Starfall Protocol",
    heroEyebrow: "游戏 Coding Agent 基础设施",
    heroStatement: "评估行为，沉淀 Rollout。",
    heroCopy: "面向游戏 Coding Agent 的 Godot-first 评测基础设施，为私有任务、隐藏评分与可训练修复轨迹而设计。",
    viewGithub: "在 GitHub 查看",
    seeBenchmark: "查看评测基准",
    runLabel: "最近一次公开 Demo 运行",
    latestRun: "最近公开 Demo",
    buildPass: "构建通过",
    runtimePass: "运行通过",
    scoreLabel: " 得分",
    proofKicker: "证据胜过描述",
    proofTitle: "代码看起来正确，不代表游戏已经完成。",
    proofLead: "GamePhanes 启动工程、执行真实输入、观测运行时状态，并在报告成功前检查确定性断言。",
    metricAssertions: "断言通过",
    metricSlices: "可玩切片",
    metricErrors: "协议错误",
    metricScore: "功能得分",
    showcaseKicker: "一款黄金 Demo，五类参考能力",
    showcaseTitle: "不是概念图，而是真正运行的 Godot 工程。",
    showcaseLead: "每个切片都有独立美术方向、完整玩法闭环、外部 Harness 和确定性评分。",
    starfallGenre: "黄金 Demo · 动作 Vertical Slice",
    starfallCopy: "在原创的 8–12 分钟 Godot 切片中，击退无人机、选择协议升级，并击败 Oracle。",
    neonGenre: "高速平台动作",
    neonCopy: "穿过霓虹天际线，完成相位跳跃，将三枚能量碎片接入中继站。",
    signalGenre: "战术生存射击",
    signalCopy: "调整战地发射器位置，在动态无线电地图中清除威胁。",
    gravityGenre: "重力解谜",
    gravityCopy: "反转极性、稳定能量核心，并打开封闭实验室出口。",
    bastionGenre: "微型塔防",
    bastionCopy: "合理分配资源，建造两座防御塔，守住黎明前的微型城堡。",
    riftGenre: "3D 竞技场战斗",
    riftCopy: "进入低多边形裂隙，击败守卫并稳定维度环。",
    playNow: "在线试玩",
    viewProject: "查看工程",
    showcaseVerified: "全部验证通过",
    workflowLabel: "GamePhanes 工作流",
    workflowKicker: "闭环游戏工程",
    workflowTitle: "从意图到经过验证的行为。",
    workflowUnderstand: "理解",
    workflowRequirements: "需求",
    workflowBuild: "构建",
    workflowProject: "Godot 工程",
    workflowRun: "运行",
    workflowHeadless: "无头引擎",
    workflowPlay: "试玩",
    workflowInputs: "真实输入",
    workflowObserve: "观测",
    workflowState: "状态与日志",
    workflowRepair: "修复",
    workflowEvidence: "基于证据",
    systemsKicker: "为智能体设计",
    systemsTitle: "运行产物，测试交互，评估行为。",
    systemSandboxTitle: "隔离的工程副本",
    systemSandboxCopy: "每次评测都在临时副本中运行，不修改原始候选工程。",
    systemHarnessTitle: "外部 Playtest Harness",
    systemHarnessCopy: "由 Benchmark 管理的驱动加载游戏、执行操作并输出结构化运行时证据。",
    systemAssertionsTitle: "确定性断言",
    systemAssertionsCopy: "移动、速度、分数、生命值等状态无需依赖不可解释的模型裁判即可评测。",
    systemHiddenTitle: "隐藏评测方向",
    systemHiddenCopy: "私有任务变体与 Benchmark 管理的评测器将在不暴露答案的情况下衡量泛化能力。",
    systemRolloutTitle: "Rollout 数据方向",
    systemRolloutCopy: "动作、Patch、运行证据、失败与成本共同组成可用于训练的修复轨迹。",
    assetsPipelineLabel: "GamePhanes 资产流水线",
    assetsKicker: "资产工程",
    assetsTitle: "资产需要契约，而不只是提示词。",
    assetsLead: "每个资产在进入场景前都可以携带来源、许可证、文件和运行时元数据。",
    assetsSpec: "资产需求",
    assetsManifest: "Manifest",
    assetsNormalize: "标准化",
    assetsValidate: "验证",
    reportKicker: "机器可读的证明",
    reportTitle: "每次运行都会生成报告。",
    reportLead: "保存结果、比较差异，或把失败作为下一轮修复提示。",
    roadmapKicker: "路线图",
    roadmapTitle: "从公开契约走向私有评测。",
    milestoneEnvironment: "运行环境",
    milestoneNow: "现在可用",
    milestoneAgent: "GamePhanes-Bench",
    milestoneRepair: "Agent Baseline",
    milestonePlaytest: "丰富观测",
    milestoneVision: "视觉与状态",
    milestoneHidden: "隐藏评测",
    milestoneTasks: "私有任务变体",
    closingKicker: "公开契约 · 隐藏评测 · 更强 Agent",
    closingTitle: "构建交互软件的评测基础设施。",
    closingButton: "在 GitHub 探索 GamePhanes",
    footerTagline: "面向游戏 Coding Agent 的评测与 Rollout 基础设施。"
  }
};

const languageButton = document.querySelector("[data-lang-toggle]");

function readSavedLanguage() {
  try {
    return window.localStorage.getItem("gamephanes-language");
  } catch {
    return null;
  }
}

function saveLanguage(language) {
  try {
    window.localStorage.setItem("gamephanes-language", language);
  } catch {
    // Language switching still works when storage is unavailable.
  }
}

function setLanguage(language) {
  const dictionary = translations[language];
  document.documentElement.lang = language === "zh" ? "zh-CN" : "en";
  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const value = dictionary[element.dataset.i18n];
    if (value) element.textContent = value;
  });
  document.querySelectorAll("[data-i18n-alt]").forEach((element) => {
    const value = dictionary[element.dataset.i18nAlt];
    if (value) element.alt = value;
  });
  document.querySelectorAll("[data-i18n-aria]").forEach((element) => {
    const value = dictionary[element.dataset.i18nAria];
    if (value) element.setAttribute("aria-label", value);
  });
  document.querySelectorAll("[data-play-link]").forEach((element) => {
    element.href = language === "zh" ? `${element.dataset.playLink}?lang=zh` : element.dataset.playLink;
  });
  if (languageButton) {
    languageButton.setAttribute("aria-pressed", String(language === "zh"));
  }
  saveLanguage(language);
}

setLanguage(readSavedLanguage() === "zh" ? "zh" : "en");
languageButton?.addEventListener("click", () => {
  const nextLanguage = document.documentElement.lang === "zh-CN" ? "en" : "zh";
  setLanguage(nextLanguage);
});

document.getElementById("copyright").textContent = new Date().getFullYear();
