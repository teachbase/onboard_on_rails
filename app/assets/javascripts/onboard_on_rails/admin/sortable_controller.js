(() => {
  if (typeof Stimulus === "undefined") return;
  const application = Stimulus.Application.start();

  application.register("sortable", class extends Stimulus.Controller {
    static values = { url: String };

    connect() {
      this.element.querySelectorAll("[data-step-id]").forEach(item => {
        item.draggable = true;
        item.addEventListener("dragstart", this.dragStart.bind(this));
        item.addEventListener("dragover", this.dragOver.bind(this));
        item.addEventListener("drop", this.drop.bind(this));
        item.addEventListener("dragend", this.dragEnd.bind(this));
      });
    }

    dragStart(e) { this.draggedItem = e.currentTarget; e.currentTarget.style.opacity = "0.4"; e.dataTransfer.effectAllowed = "move"; }

    dragOver(e) {
      e.preventDefault(); e.dataTransfer.dropEffect = "move";
      const target = e.currentTarget;
      if (target !== this.draggedItem) {
        const rect = target.getBoundingClientRect();
        if (e.clientY < rect.top + rect.height / 2) target.parentNode.insertBefore(this.draggedItem, target);
        else target.parentNode.insertBefore(this.draggedItem, target.nextSibling);
      }
    }

    drop(e) { e.preventDefault(); this.saveOrder(); }

    dragEnd(e) { e.currentTarget.style.opacity = "1"; this.draggedItem = null; }

    saveOrder() {
      const items = this.element.querySelectorAll("[data-step-id]");
      const order = Array.from(items).map((item, i) => ({ id: item.dataset.stepId, position: i + 1 }));
      if (this.urlValue) {
        const csrfToken = document.querySelector('meta[name="csrf-token"]');
        fetch(this.urlValue, {
          method: "PATCH",
          headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken ? csrfToken.content : "" },
          body: JSON.stringify({ order })
        });
      }
    }
  });
})();
