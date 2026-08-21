const query = new URLSearchParams(window.location.search);
const language = query.get("lang") === "zh" ? "zh" : "en";
const frame = document.querySelector("[data-game-frame]");
const stage = document.querySelector("[data-stage]");
const loading = document.querySelector("[data-loading]");
const controlsContainer = document.querySelector("[data-touch-controls-container]");
let gameReady = false;

const labels = {
  en: { back: "Back to showcase", loading: "Loading game...", reload: "Reload game", fullscreen: "Enter fullscreen", controls: "Touch game controls" },
  zh: { back: "返回游戏展示", loading: "正在加载游戏...", reload: "重新开始", fullscreen: "进入全屏", controls: "触屏游戏控制" },
};

document.documentElement.lang = language === "zh" ? "zh-CN" : "en";
document.querySelectorAll("[data-label]").forEach((element) => {
  element.textContent = labels[language][element.dataset.label];
});
document.querySelector("[data-controls-copy]").textContent = document.body.dataset[language === "zh" ? "controlsZh" : "controlsEn"];

const reloadButton = document.querySelector("[data-reload]");
const fullscreenButton = document.querySelector("[data-fullscreen]");
reloadButton.title = labels[language].reload;
reloadButton.setAttribute("aria-label", labels[language].reload);
fullscreenButton.title = labels[language].fullscreen;
fullscreenButton.setAttribute("aria-label", labels[language].fullscreen);
controlsContainer.setAttribute("aria-label", labels[language].controls);

frame.addEventListener("load", () => {
  frame.contentWindow?.focus();
  frame.contentDocument?.getElementById("canvas")?.focus();
});

window.addEventListener("message", (event) => {
  if (event.origin !== window.location.origin || event.source !== frame.contentWindow || event.data !== "gamephanes-ready") return;
  gameReady = true;
  loading.classList.add("is-hidden");
  document.querySelectorAll(".touch-control").forEach((button) => {
    button.disabled = false;
  });
});

reloadButton.addEventListener("click", () => {
  gameReady = false;
  loading.classList.remove("is-hidden");
  document.querySelectorAll(".touch-control").forEach((button) => {
    button.disabled = true;
  });
  frame.contentWindow.location.reload();
});

fullscreenButton.addEventListener("click", async () => {
  if (document.fullscreenElement) {
    await document.exitFullscreen();
  } else {
    await stage.requestFullscreen();
  }
});

function dispatchKey(type, control) {
  frame.contentWindow?.postMessage(`gamephanes-input|${control.actionName}|${type === "keydown" ? "1" : "0"}`, window.location.origin);
  const target = frame.contentDocument?.getElementById("canvas");
  if (!target) return;
  target.focus();
  target.dispatchEvent(new KeyboardEvent(type, {
    key: control.key,
    code: control.code,
    bubbles: true,
    cancelable: true,
  }));
}

const touchControls = JSON.parse(document.body.dataset.touchControls);
for (const control of touchControls) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = `touch-control${control.action ? " is-action" : ""}`;
  button.disabled = !gameReady;
  button.textContent = language === "zh" && control.labelZh ? control.labelZh : control.label;
  button.setAttribute("aria-label", language === "zh" ? control.ariaZh : control.ariaEn);

  let pressedAt = 0;
  let pressed = false;
  const release = () => {
    if (!pressed) return;
    pressed = false;
    if (control.action) {
      button.classList.remove("is-pressed");
      return;
    }
    const remainingHold = Math.max(0, 80 - (performance.now() - pressedAt));
    window.setTimeout(() => {
      dispatchKey("keyup", control);
      button.classList.remove("is-pressed");
    }, remainingHold);
  };
  button.addEventListener("pointerdown", (event) => {
    event.preventDefault();
    button.setPointerCapture(event.pointerId);
    pressedAt = performance.now();
    pressed = true;
    if (!control.action) dispatchKey("keydown", control);
    button.classList.add("is-pressed");
  });
  button.addEventListener("pointerup", release);
  button.addEventListener("pointercancel", release);
  button.addEventListener("lostpointercapture", release);
  button.addEventListener("click", (event) => {
    if (!control.action && event.detail !== 0) return;
    dispatchKey("keydown", control);
    window.setTimeout(() => dispatchKey("keyup", control), 80);
  });
  controlsContainer.appendChild(button);
}
