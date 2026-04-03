(() => {
  if (typeof Stimulus === "undefined") return;
  const application = Stimulus.Application.start();

  application.register("selector-picker", class extends Stimulus.Controller {
    static targets = ["input"];

    connect() { window.addEventListener("message", this.handleMessage.bind(this)); }
    disconnect() { window.removeEventListener("message", this.handleMessage.bind(this)); }

    handleMessage(event) {
      if (event.data && event.data.type === "oor-selector-picked" && this.hasInputTarget) {
        this.inputTarget.value = event.data.selector;
        this.inputTarget.dispatchEvent(new Event("input"));
      }
    }
  });
})();
