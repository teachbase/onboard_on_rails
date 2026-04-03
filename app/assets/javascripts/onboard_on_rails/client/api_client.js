window.OnboardOnRails = window.OnboardOnRails || {};

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
  async updateCompletion(tourId, stepId, status, sessionId) {
    const mountPath = this.getMountPath();
    const response = await fetch(`${mountPath}/api/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": this.getCsrfToken() },
      body: JSON.stringify({ tour_id: tourId, step_id: stepId, status, session_id: sessionId })
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
  }
};
