document.querySelectorAll("[data-copy-text]").forEach((button) => {
  button.addEventListener("click", async () => {
    const originalLabel = button.textContent;
    try {
      await navigator.clipboard.writeText(button.dataset.copyText);
      button.textContent = "Copied";
      window.setTimeout(() => {
        button.textContent = originalLabel;
      }, 1400);
    } catch {
      button.textContent = "Copy failed";
    }
  });
});

document.querySelectorAll("[data-copyright]").forEach((element) => {
  element.textContent = new Date().getFullYear();
});
