window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.DOMObserver = {
  mutationObserver: null, waitCallbacks: [],

  start(onNavigate) {
    document.addEventListener("turbo:load", () => onNavigate());
    document.addEventListener("turbo:before-render", () => OnboardOnRails.TourRenderer.cleanup());
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
