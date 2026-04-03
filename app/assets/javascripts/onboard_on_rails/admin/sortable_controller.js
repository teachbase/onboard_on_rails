document.addEventListener("DOMContentLoaded", function() {
  var wrapper = document.querySelector("[data-controller='sortable']");
  if (!wrapper) return;

  var sortableUrl = wrapper.getAttribute("data-sortable-url-value");
  var draggedItem = null;

  wrapper.querySelectorAll("[data-step-id]").forEach(function(item) {
    item.draggable = true;

    item.addEventListener("dragstart", function(e) {
      draggedItem = e.currentTarget;
      e.currentTarget.style.opacity = "0.4";
      e.dataTransfer.effectAllowed = "move";
    });

    item.addEventListener("dragover", function(e) {
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      var target = e.currentTarget;
      if (target !== draggedItem) {
        var rect = target.getBoundingClientRect();
        if (e.clientY < rect.top + rect.height / 2) {
          target.parentNode.insertBefore(draggedItem, target);
        } else {
          target.parentNode.insertBefore(draggedItem, target.nextSibling);
        }
      }
    });

    item.addEventListener("drop", function(e) {
      e.preventDefault();
      saveOrder();
    });

    item.addEventListener("dragend", function(e) {
      e.currentTarget.style.opacity = "1";
      draggedItem = null;
    });
  });

  function saveOrder() {
    var items = wrapper.querySelectorAll("[data-step-id]");
    var order = Array.from(items).map(function(item, i) {
      return { id: item.dataset.stepId, position: i + 1 };
    });
    if (sortableUrl) {
      var csrfToken = document.querySelector('meta[name="csrf-token"]');
      fetch(sortableUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken ? csrfToken.content : ""
        },
        body: JSON.stringify({ order: order })
      });
    }
  }
});
