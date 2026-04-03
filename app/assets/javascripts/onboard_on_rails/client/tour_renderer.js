window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.TourRenderer = {
  overlay: null, tooltip: null, resizeHandler: null,

  show(tour, stepIndex, callbacks) {
    this.cleanup();
    const step = tour.steps[stepIndex];
    if (!step) return;
    const targetEl = step.placement === "center" ? null : document.querySelector(step.selector);
    if (!targetEl && step.placement !== "center") return;
    this.createOverlay(targetEl);
    this.createTooltip(tour, step, stepIndex, tour.steps.length, targetEl, callbacks);
    if (targetEl) OnboardOnRails.PositioningEngine.scrollIntoView(targetEl);
    this.resizeHandler = () => {
      if (targetEl) {
        this.overlay.style.clipPath = OnboardOnRails.PositioningEngine.getClipPath(targetEl);
        OnboardOnRails.PositioningEngine.position(this.tooltip, targetEl, step.placement);
      }
    };
    window.addEventListener("resize", this.resizeHandler);
    window.addEventListener("scroll", this.resizeHandler);
  },

  createOverlay(targetEl) {
    this.overlay = document.createElement("div");
    this.overlay.className = "oor-overlay";
    if (targetEl) this.overlay.style.clipPath = OnboardOnRails.PositioningEngine.getClipPath(targetEl);
    document.body.appendChild(this.overlay);
  },

  createTooltip(tour, step, stepIndex, totalSteps, targetEl, callbacks) {
    this.tooltip = document.createElement("div");
    OnboardOnRails.ThemeEngine.applyTheme(this.tooltip, tour.theme, tour.style_overrides, step.style_overrides);
    const isFirst = stepIndex === 0;
    const isLast = stepIndex === totalSteps - 1;
    this.tooltip.innerHTML = `
      <div class="oor-step-content">
        <div class="oor-step-title">${this.escapeHtml(step.title)}</div>
        <div class="oor-step-body">${step.body}</div>
      </div>
      <div class="oor-step-footer">
        <div class="oor-step-dots">
          ${tour.steps.map((_, i) => `<span class="oor-dot ${i === stepIndex ? 'oor-dot--active' : ''}"></span>`).join("")}
        </div>
        <div class="oor-step-actions">
          <button class="oor-btn-skip" data-action="dismiss">Skip</button>
          ${!isFirst ? '<button class="oor-btn-prev" data-action="prev">Back</button>' : ''}
          <button class="oor-btn-next" data-action="${isLast ? 'complete' : 'next'}">${isLast ? 'Done' : 'Next'}</button>
        </div>
      </div>`;
    this.tooltip.addEventListener("click", (e) => {
      const action = e.target.dataset.action;
      if (action && callbacks[action]) callbacks[action]();
    });
    document.body.appendChild(this.tooltip);
    if (targetEl) {
      OnboardOnRails.PositioningEngine.position(this.tooltip, targetEl, step.placement);
    } else {
      this.tooltip.style.position = "fixed";
      this.tooltip.style.top = "50%";
      this.tooltip.style.left = "50%";
      this.tooltip.style.transform = "translate(-50%, -50%)";
      this.tooltip.style.zIndex = "10001";
    }
  },

  cleanup() {
    if (this.overlay) { this.overlay.remove(); this.overlay = null; }
    if (this.tooltip) { this.tooltip.remove(); this.tooltip = null; }
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler);
      window.removeEventListener("scroll", this.resizeHandler);
      this.resizeHandler = null;
    }
  },

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
};
