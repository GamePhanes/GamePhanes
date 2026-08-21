const translations = {
  en: {
    navWorkflow: "Workflow",
    navBenchmark: "Benchmark",
    navArchitecture: "Architecture",
    heroImageAlt: "A GameBuddy platformer playtest with the player jumping toward a coin",
    heroEyebrow: "Open-source autonomous game engineering",
    heroStatement: "Build. Play. Prove.",
    heroCopy: "A Godot-first coding agent environment that turns game requirements into runnable projects, real playtests, and reproducible evidence.",
    viewGithub: "View on GitHub",
    seeBenchmark: "See the benchmark",
    runLabel: "Latest verified run",
    latestRun: "LATEST RUN",
    buildPass: "BUILD PASS",
    runtimePass: "RUNTIME PASS",
    scoreLabel: " SCORE",
    proofKicker: "Evidence over claims",
    proofTitle: "A game is not done when the code looks right.",
    proofLead: "GameBuddy launches the project, performs real inputs, observes runtime state, and checks deterministic assertions before reporting success.",
    metricAssertions: "Assertions passed",
    metricRuntime: "Playtest runtime",
    metricErrors: "Protocol errors",
    metricScore: "Functional score",
    workflowLabel: "GameBuddy workflow",
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
    systemsTitle: "The missing runtime layer for game coding agents.",
    systemSandboxTitle: "Sandboxed project copies",
    systemSandboxCopy: "Every evaluation runs against a temporary copy, leaving the original candidate project unchanged.",
    systemHarnessTitle: "External playtest harnesses",
    systemHarnessCopy: "Benchmark-owned drivers load the game, perform actions, and emit structured runtime evidence.",
    systemAssertionsTitle: "Deterministic assertions",
    systemAssertionsCopy: "Movement, velocity, score, health, and other state can be evaluated without an opaque model judge.",
    reportKicker: "Machine-readable proof",
    reportTitle: "Every run ends with a report.",
    reportLead: "Store it, compare it, or use failures as the next repair prompt.",
    roadmapKicker: "Roadmap",
    roadmapTitle: "Small core. Serious trajectory.",
    milestoneEnvironment: "Environment",
    milestoneNow: "Available now",
    milestoneAgent: "Coding Agent",
    milestoneRepair: "Repair loop",
    milestonePlaytest: "Playtest DSL",
    milestoneVision: "Vision + state",
    milestoneTasks: "10 verified tasks",
    closingKicker: "MIT licensed. Godot-first. Built in public.",
    closingTitle: "Help build the benchmark games can actually pass.",
    closingButton: "Explore GameBuddy on GitHub",
    footerTagline: "Open-source autonomous game engineering."
  },
  zh: {
    navWorkflow: "工作流",
    navBenchmark: "评测基准",
    navArchitecture: "架构",
    heroImageAlt: "GameBuddy 平台跳跃 Playtest，玩家正在跳向金币",
    heroEyebrow: "开源自主游戏工程",
    heroStatement: "构建 · 试玩 · 证明",
    heroCopy: "面向 Godot 的游戏编码智能体环境，把游戏需求转化为可运行工程、真实试玩和可复现证据。",
    viewGithub: "在 GitHub 查看",
    seeBenchmark: "查看评测基准",
    runLabel: "最近一次验证运行",
    latestRun: "最近运行",
    buildPass: "构建通过",
    runtimePass: "运行通过",
    scoreLabel: " 得分",
    proofKicker: "证据胜过描述",
    proofTitle: "代码看起来正确，不代表游戏已经完成。",
    proofLead: "GameBuddy 启动工程、执行真实输入、观测运行时状态，并在报告成功前检查确定性断言。",
    metricAssertions: "断言通过",
    metricRuntime: "试玩耗时",
    metricErrors: "协议错误",
    metricScore: "功能得分",
    workflowLabel: "GameBuddy 工作流",
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
    systemsTitle: "游戏编码智能体缺失的运行时层。",
    systemSandboxTitle: "隔离的工程副本",
    systemSandboxCopy: "每次评测都在临时副本中运行，不修改原始候选工程。",
    systemHarnessTitle: "外部 Playtest Harness",
    systemHarnessCopy: "由 Benchmark 管理的驱动加载游戏、执行操作并输出结构化运行时证据。",
    systemAssertionsTitle: "确定性断言",
    systemAssertionsCopy: "移动、速度、分数、生命值等状态无需依赖不可解释的模型裁判即可评测。",
    reportKicker: "机器可读的证明",
    reportTitle: "每次运行都会生成报告。",
    reportLead: "保存结果、比较差异，或把失败作为下一轮修复提示。",
    roadmapKicker: "路线图",
    roadmapTitle: "核心保持小巧，目标持续推进。",
    milestoneEnvironment: "运行环境",
    milestoneNow: "现在可用",
    milestoneAgent: "编码智能体",
    milestoneRepair: "修复闭环",
    milestonePlaytest: "Playtest DSL",
    milestoneVision: "视觉与状态",
    milestoneTasks: "10 个验证任务",
    closingKicker: "MIT 许可证 · Godot 优先 · 开源共建",
    closingTitle: "一起构建真正能通过评测的游戏。",
    closingButton: "在 GitHub 探索 GameBuddy",
    footerTagline: "开源自主游戏工程。"
  }
};

const languageButton = document.querySelector("[data-lang-toggle]");

function readSavedLanguage() {
  try {
    return window.localStorage.getItem("gamebuddy-language");
  } catch {
    return null;
  }
}

function saveLanguage(language) {
  try {
    window.localStorage.setItem("gamebuddy-language", language);
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
