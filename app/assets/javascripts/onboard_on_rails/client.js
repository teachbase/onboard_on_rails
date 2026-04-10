// OnboardOnRails Client Bundle
// Compatible with both Sprockets and Propshaft

window.OnboardOnRails = window.OnboardOnRails || {};

// === ApiClient ===
OnboardOnRails.ApiClient = {
  getMountPath() {
    const meta = document.querySelector('meta[name="onboard-on-rails-mount-path"]');
    return meta ? meta.content : "/onboard";
  },
  getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : "";
  },
  getUserId() {
    const meta = document.querySelector('meta[name="onboard-on-rails-user-id"]');
    return meta ? meta.content : null;
  },
  async fetchTours(url, sessionId) {
    if (!this.getUserId()) return null;
    const mountPath = this.getMountPath();
    const params = new URLSearchParams({ url });
    if (sessionId) params.append("session_id", sessionId);
    const response = await fetch(`${mountPath}/api/tours?${params}`, { headers: { "Accept": "application/json" } });
    if (!response.ok) return null;
    const data = await response.json();
    return data.tour;
  },
  async updateCompletion(tourId, stepId, status, sessionId, matchedUrl, matchedStepId) {
    const mountPath = this.getMountPath();
    const body = { tour_id: tourId, step_id: stepId, status, session_id: sessionId };
    if (matchedUrl && matchedStepId) {
      body.matched_url = matchedUrl;
      body.matched_step_id = matchedStepId;
    }
    const response = await fetch(`${mountPath}/api/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.getCsrfToken() },
      body: JSON.stringify(body)
    });
    return response.ok;
  },
  async trackEvent(name, payload) {
    const mountPath = this.getMountPath();
    const response = await fetch(`${mountPath}/api/events`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.getCsrfToken() },
      body: JSON.stringify({ name, payload: payload || {} })
    });
    return response.ok;
  },
  sendCompletionBeacon(tourId, stepId, status, sessionId, matchedUrl, matchedStepId) {
    const mountPath = this.getMountPath();
    const body = { tour_id: tourId, step_id: stepId, status, session_id: sessionId };
    if (matchedUrl && matchedStepId) {
      body.matched_url = matchedUrl;
      body.matched_step_id = matchedStepId;
    }
    const blob = new Blob([JSON.stringify(body)], { type: "application/json" });
    navigator.sendBeacon(`${mountPath}/api/completions`, blob);
  }
};

// === ThemeEngine ===
OnboardOnRails.ThemeEngine = {
  applyTheme(container, theme, tourOverrides, stepOverrides) {
    container.className = "oor-tour-step";
    container.classList.add(`oor-theme-${theme}`);
    const overrides = Object.assign({}, tourOverrides || {}, stepOverrides || {});
    if (overrides.background) container.style.setProperty("--oor-step-bg", overrides.background);
    if (overrides.text_color) container.style.setProperty("--oor-step-text", overrides.text_color);
    if (overrides.font_family) container.style.setProperty("--oor-step-font", overrides.font_family);
    if (overrides.font_size) container.style.setProperty("--oor-step-font-size", overrides.font_size);
    if (overrides.border_radius) container.style.setProperty("--oor-step-radius", overrides.border_radius);
    if (overrides.button_color) container.style.setProperty("--oor-step-btn-bg", overrides.button_color);
    if (overrides.max_width) container.style.setProperty("--oor-step-max-width", overrides.max_width);
  }
};

// === PositioningEngine ===
OnboardOnRails.PositioningEngine = {
  MARGIN: 12,
  position(tooltip, targetEl, placement) {
    const targetRect = targetEl.getBoundingClientRect();
    const tooltipRect = tooltip.getBoundingClientRect();
    const scrollX = window.scrollX;
    const scrollY = window.scrollY;
    let top, left;
    const resolved = this.resolvePlacement(placement, targetRect, tooltipRect);
    switch (resolved) {
      case "top":
        top = targetRect.top + scrollY - tooltipRect.height - this.MARGIN;
        left = targetRect.left + scrollX + (targetRect.width - tooltipRect.width) / 2;
        break;
      case "bottom":
        top = targetRect.bottom + scrollY + this.MARGIN;
        left = targetRect.left + scrollX + (targetRect.width - tooltipRect.width) / 2;
        break;
      case "left":
        top = targetRect.top + scrollY + (targetRect.height - tooltipRect.height) / 2;
        left = targetRect.left + scrollX - tooltipRect.width - this.MARGIN;
        break;
      case "right":
        top = targetRect.top + scrollY + (targetRect.height - tooltipRect.height) / 2;
        left = targetRect.right + scrollX + this.MARGIN;
        break;
      case "center":
        top = targetRect.top + scrollY + (targetRect.height - tooltipRect.height) / 2;
        left = targetRect.left + scrollX + (targetRect.width - tooltipRect.width) / 2;
        break;
    }
    left = Math.max(this.MARGIN, Math.min(left, window.innerWidth + scrollX - tooltipRect.width - this.MARGIN));
    top = Math.max(this.MARGIN, top);
    tooltip.style.position = "absolute";
    tooltip.style.top = top + "px";
    tooltip.style.left = left + "px";
    tooltip.dataset.placement = resolved;
  },
  resolvePlacement(preferred, targetRect, tooltipRect) {
    if (preferred === "center") return "center";
    const space = {
      top: targetRect.top - this.MARGIN,
      bottom: window.innerHeight - targetRect.bottom - this.MARGIN,
      left: targetRect.left - this.MARGIN,
      right: window.innerWidth - targetRect.right - this.MARGIN
    };
    const needed = { top: tooltipRect.height, bottom: tooltipRect.height, left: tooltipRect.width, right: tooltipRect.width };
    if (space[preferred] >= needed[preferred]) return preferred;
    const opposite = { top: "bottom", bottom: "top", left: "right", right: "left" };
    if (space[opposite[preferred]] >= needed[opposite[preferred]]) return opposite[preferred];
    return Object.entries(space).sort((a, b) => b[1] - a[1])[0][0];
  },
  getClipPath(targetEl) {
    const rect = targetEl.getBoundingClientRect();
    const pad = 4;
    const x = rect.left - pad, y = rect.top - pad;
    const w = rect.width + pad * 2, h = rect.height + pad * 2;
    const r = 4;
    return `polygon(evenodd, 0% 0%, 100% 0%, 100% 100%, 0% 100%, 0% 0%, ${x}px ${y+r}px, ${x+r}px ${y}px, ${x+w-r}px ${y}px, ${x+w}px ${y+r}px, ${x+w}px ${y+h-r}px, ${x+w-r}px ${y+h}px, ${x+r}px ${y+h}px, ${x}px ${y+h-r}px, ${x}px ${y+r}px)`;
  },
  scrollIntoView(targetEl) {
    const rect = targetEl.getBoundingClientRect();
    if (rect.top < 0 || rect.bottom > window.innerHeight) {
      targetEl.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }
};

// === SelectorGenerator ===
OnboardOnRails.SelectorGenerator = {
  generate(element) {
    if (element.id) return `#${element.id}`;
    const unique = this.findUniqueClass(element);
    if (unique) return unique;
    return this.buildPath(element);
  },
  findUniqueClass(element) {
    for (const cls of element.classList) {
      if (cls.startsWith("js-") || cls.startsWith("oor-")) continue;
      const matches = document.querySelectorAll(`.${CSS.escape(cls)}`);
      if (matches.length === 1) return `.${cls}`;
    }
    return null;
  },
  buildPath(element) {
    const parts = [];
    let current = element;
    while (current && current !== document.body) {
      let selector = current.tagName.toLowerCase();
      if (current.id) { parts.unshift(`#${current.id}`); break; }
      const parent = current.parentElement;
      if (parent) {
        const siblings = Array.from(parent.children).filter(c => c.tagName === current.tagName);
        if (siblings.length > 1) { const index = siblings.indexOf(current) + 1; selector += `:nth-of-type(${index})`; }
      }
      parts.unshift(selector);
      current = parent;
    }
    return parts.join(" > ");
  }
};

// === DOMObserver ===
OnboardOnRails.DOMObserver = {
  mutationObserver: null, waitCallbacks: [],

  start(onNavigate) {
    document.addEventListener("turbo:load", () => onNavigate());
    document.addEventListener("turbo:before-render", () => OnboardOnRails.TourRenderer.cleanup());
    document.addEventListener("turbo:before-cache", () => OnboardOnRails.TourRenderer.cleanup());
    this.mutationObserver = new MutationObserver(() => this.checkWaitCallbacks());
    this.mutationObserver.observe(document.body, { childList: true, subtree: true });
  },

  stop() {
    if (this.mutationObserver) { this.mutationObserver.disconnect(); this.mutationObserver = null; }
    this.waitCallbacks = [];
  },

  waitForSelector(selector, callback, timeoutMs) {
    const el = document.querySelector(selector);
    if (el) { callback(el); return; }
    this.waitCallbacks.push({ selector, callback, added: Date.now(), timeoutMs: timeoutMs || 10000 });
  },

  checkWaitCallbacks() {
    const now = Date.now();
    this.waitCallbacks = this.waitCallbacks.filter(entry => {
      if (now - entry.added > entry.timeoutMs) return false;
      const el = document.querySelector(entry.selector);
      if (el) { entry.callback(el); return false; }
      return true;
    });
  }
};

// === TourRenderer ===
OnboardOnRails.TourRenderer = {
  overlay: null, tooltip: null, resizeHandler: null,

  targetEl: null,
  originalStyles: null,

  show(tour, stepIndex, callbacks) {
    this.cleanup();
    const step = tour.steps[stepIndex];
    if (!step) return;
    this.targetEl = step.selector ? document.querySelector(step.selector) : null;
    if (!this.targetEl && step.placement !== "center") return;
    this.createOverlay(this.targetEl);
    this.highlightTarget(this.targetEl);
    this.createTooltip(tour, step, stepIndex, tour.steps.length, this.targetEl, callbacks);
    if (this.targetEl) OnboardOnRails.PositioningEngine.scrollIntoView(this.targetEl);
    this.resizeHandler = () => {
      if (this.targetEl) {
        this.overlay.style.clipPath = OnboardOnRails.PositioningEngine.getClipPath(this.targetEl);
        OnboardOnRails.PositioningEngine.position(this.tooltip, this.targetEl, step.placement);
      }
    };
    window.addEventListener("resize", this.resizeHandler);
    window.addEventListener("scroll", this.resizeHandler);
  },

  highlightTarget(el) {
    if (!el) return;
    this.originalStyles = {
      position: el.style.position,
      zIndex: el.style.zIndex,
      position_computed: window.getComputedStyle(el).position
    };
    if (this.originalStyles.position_computed === "static") {
      el.style.position = "relative";
    }
    el.style.zIndex = "10001";
  },

  restoreTarget() {
    if (this.targetEl && this.originalStyles) {
      if (this.originalStyles.position_computed === "static") {
        this.targetEl.style.position = this.originalStyles.position;
      }
      this.targetEl.style.zIndex = this.originalStyles.zIndex;
    }
    this.targetEl = null;
    this.originalStyles = null;
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
        ${totalSteps > 5
          ? `<div class="oor-step-counter">${stepIndex + 1} / ${totalSteps}</div>`
          : `<div class="oor-step-dots">${tour.steps.map((_, i) => `<span class="oor-dot ${i === stepIndex ? 'oor-dot--active' : ''}"></span>`).join("")}</div>`
        }
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
    this.restoreTarget();
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

// === TourManager ===
OnboardOnRails.TourManager = {
  currentTour: null, currentStepIndex: 0, sessionId: null,
  _targetClickEl: null, _targetClickHandler: null,
  _loadVersion: 0,

  init() {
    if (!OnboardOnRails.ApiClient.getUserId()) return;
    this.sessionId = this.getOrCreateSessionId();
    this.loadTour();
    OnboardOnRails.DOMObserver.start(() => this.loadTour());
  },

  async loadTour() {
    var version = ++this._loadVersion;
    var url = window.location.pathname;
    var tour = await OnboardOnRails.ApiClient.fetchTours(url, this.sessionId);
    if (version !== this._loadVersion) return;

    if (tour && this.currentTour && tour.id === this.currentTour.id &&
        this.currentStepIndex === (tour.current_step_index || 0)) {
      return;
    }

    OnboardOnRails.TourRenderer.cleanup();
    if (!tour) { this.currentTour = null; return; }
    this.currentTour = tour;
    this.currentStepIndex = tour.current_step_index || 0;
    this.showStep();
  },

  showStep(allowRedirect) {
    if (!this.currentTour) return;
    this._clearTargetClickListener();
    const step = this.currentTour.steps[this.currentStepIndex];
    if (!step) return;

    // Redirect to step's page only during explicit navigation (next/prev),
    // not on initial load — the backend already validates URL matching.
    if (allowRedirect && step.url_pattern && !step.url_pattern.includes("*")) {
      if (window.location.pathname !== step.url_pattern) {
        window.location.href = step.url_pattern;
        return;
      }
    }

    const showFn = () => {
      OnboardOnRails.TourRenderer.show(this.currentTour, this.currentStepIndex, {
        next: () => this.next(), prev: () => this.prev(),
        dismiss: () => this.dismiss(), complete: () => this.complete()
      });
      this._attachTargetClickListener(step);
    };
    if (step.wait_for_selector) {
      OnboardOnRails.DOMObserver.waitForSelector(step.wait_for_selector, showFn);
    } else {
      const targetEl = (step.placement === "center" && !step.selector) ? true : document.querySelector(step.selector);
      if (targetEl) showFn();
      else OnboardOnRails.DOMObserver.waitForSelector(step.selector, showFn);
    }
  },

  async next() {
    this._clearTargetClickListener();
    const currentStep = this.currentTour.steps[this.currentStepIndex];
    const nextIndex = this.currentStepIndex + 1;
    const nextStep = this.currentTour.steps[nextIndex];

    if (nextStep) {
      await OnboardOnRails.ApiClient.updateCompletion(
        this.currentTour.id, nextStep.id, "in_progress", this.sessionId,
        window.location.pathname, currentStep.id
      );
    }

    if (currentStep.action_type === "redirect" && currentStep.action_value) {
      window.location.href = currentStep.action_value;
      return;
    }
    if (currentStep.action_type === "custom_event" && currentStep.action_value) {
      await OnboardOnRails.ApiClient.trackEvent(currentStep.action_value);
    }

    this.currentStepIndex = nextIndex;
    if (this.currentStepIndex < this.currentTour.steps.length) {
      this.showStep(true);
    } else {
      this.complete();
    }
  },

  async prev() {
    this._clearTargetClickListener();
    if (this.currentStepIndex <= 0) return;

    const prevIndex = this.currentStepIndex - 1;
    const prevStep = this.currentTour.steps[prevIndex];

    await OnboardOnRails.ApiClient.updateCompletion(
      this.currentTour.id, prevStep.id, "in_progress", this.sessionId
    );

    if (prevStep.matched_url && prevStep.matched_url !== window.location.pathname) {
      window.location.href = prevStep.matched_url;
      return;
    }

    this.currentStepIndex = prevIndex;
    this.showStep(true);
  },

  async dismiss() {
    this._clearTargetClickListener();
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(this.currentTour.id, step.id, "dismissed", this.sessionId);
    OnboardOnRails.TourRenderer.cleanup();
    this.currentTour = null;
  },

  async complete() {
    this._clearTargetClickListener();
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(this.currentTour.id, step.id, "completed", this.sessionId);
    OnboardOnRails.TourRenderer.cleanup();
    this.currentTour = null;
  },

  getOrCreateSessionId() {
    let id = sessionStorage.getItem("oor_session_id");
    if (!id) { id = Math.random().toString(36).substring(2) + Date.now().toString(36); sessionStorage.setItem("oor_session_id", id); }
    return id;
  },

  _clearTargetClickListener() {
    if (this._targetClickEl && this._targetClickHandler) {
      this._targetClickEl.removeEventListener("click", this._targetClickHandler);
    }
    this._targetClickEl = null;
    this._targetClickHandler = null;
  },

  _attachTargetClickListener(step) {
    if (!step.complete_on_target_click) return;

    const targetEl = document.querySelector(step.selector);
    if (!targetEl) return;

    const tour = this.currentTour;
    const currentStep = step;
    const stepIndex = this.currentStepIndex;
    const isLast = stepIndex === tour.steps.length - 1;
    const nextStep = tour.steps[stepIndex + 1];

    this._targetClickHandler = () => {
      this._clearTargetClickListener();

      if (isLast) {
        OnboardOnRails.ApiClient.sendCompletionBeacon(
          tour.id, currentStep.id, "completed", this.sessionId
        );
        this.currentTour = null;
      } else if (nextStep) {
        OnboardOnRails.ApiClient.sendCompletionBeacon(
          tour.id, nextStep.id, "in_progress", this.sessionId,
          window.location.pathname, currentStep.id
        );
      }
    };

    this._targetClickEl = targetEl;
    targetEl.addEventListener("click", this._targetClickHandler);
  }
};

OnboardOnRails.trackEvent = function(name, payload) { return OnboardOnRails.ApiClient.trackEvent(name, payload); };

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => OnboardOnRails.TourManager.init());
} else {
  OnboardOnRails.TourManager.init();
}
