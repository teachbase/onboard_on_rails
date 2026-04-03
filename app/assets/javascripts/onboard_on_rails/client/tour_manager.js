window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.TourManager = {
  currentTour: null, currentStepIndex: 0, sessionId: null,

  init() {
    if (!OnboardOnRails.ApiClient.getUserId()) return;
    this.sessionId = this.getOrCreateSessionId();
    this.loadTour();
    OnboardOnRails.DOMObserver.start(() => this.loadTour());
  },

  async loadTour() {
    OnboardOnRails.TourRenderer.cleanup();
    const url = window.location.pathname;
    const tour = await OnboardOnRails.ApiClient.fetchTours(url, this.sessionId);
    if (!tour) { this.currentTour = null; return; }
    this.currentTour = tour;
    this.currentStepIndex = 0;
    this.showStep();
  },

  showStep() {
    if (!this.currentTour) return;
    const step = this.currentTour.steps[this.currentStepIndex];
    if (!step) return;
    if (step.url_pattern && !this.matchesCurrentUrl(step.url_pattern)) {
      window.location.href = step.url_pattern;
      return;
    }
    const showFn = () => {
      OnboardOnRails.TourRenderer.show(this.currentTour, this.currentStepIndex, {
        next: () => this.next(), prev: () => this.prev(),
        dismiss: () => this.dismiss(), complete: () => this.complete()
      });
    };
    if (step.wait_for_selector) {
      OnboardOnRails.DOMObserver.waitForSelector(step.wait_for_selector, showFn);
    } else {
      const targetEl = step.placement === "center" ? true : document.querySelector(step.selector);
      if (targetEl) showFn();
      else OnboardOnRails.DOMObserver.waitForSelector(step.selector, showFn);
    }
  },

  async next() {
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(this.currentTour.id, step.id, "in_progress", this.sessionId);
    if (step.action_type === "redirect" && step.action_value) { window.location.href = step.action_value; return; }
    if (step.action_type === "custom_event" && step.action_value) await OnboardOnRails.ApiClient.trackEvent(step.action_value);
    this.currentStepIndex++;
    if (this.currentStepIndex < this.currentTour.steps.length) this.showStep();
    else this.complete();
  },

  prev() { if (this.currentStepIndex > 0) { this.currentStepIndex--; this.showStep(); } },

  async dismiss() {
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(this.currentTour.id, step.id, "dismissed", this.sessionId);
    OnboardOnRails.TourRenderer.cleanup();
    this.currentTour = null;
  },

  async complete() {
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(this.currentTour.id, step.id, "completed", this.sessionId);
    OnboardOnRails.TourRenderer.cleanup();
    this.currentTour = null;
  },

  matchesCurrentUrl(pattern) {
    return window.location.pathname === pattern || window.location.pathname.startsWith(pattern.replace("*", ""));
  },

  getOrCreateSessionId() {
    let id = sessionStorage.getItem("oor_session_id");
    if (!id) { id = Math.random().toString(36).substring(2) + Date.now().toString(36); sessionStorage.setItem("oor_session_id", id); }
    return id;
  }
};

OnboardOnRails.trackEvent = function(name, payload) { return OnboardOnRails.ApiClient.trackEvent(name, payload); };

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => OnboardOnRails.TourManager.init());
} else {
  OnboardOnRails.TourManager.init();
}
