// OnboardOnRails Admin Bundle
// Compatible with both Sprockets and Propshaft

// === Step Preview Controller ===
document.addEventListener("DOMContentLoaded", function() {
  // Find the step edit form — only run on step edit pages
  var form = document.querySelector("[data-controller='step-preview']");
  if (!form) return;

  function updatePreview() {
    var title = document.querySelector("[data-step-preview-target='title']");
    var body = document.querySelector("[data-step-preview-target='body']");
    var previewTitle = document.querySelector("[data-step-preview-target='previewTitle']");
    var previewBody = document.querySelector("[data-step-preview-target='previewBody']");
    var previewButton = document.querySelector("[data-step-preview-target='previewButton']");
    var bgColor = document.querySelector("[data-step-preview-target='bgColor']");
    var textColor = document.querySelector("[data-step-preview-target='textColor']");
    var buttonColor = document.querySelector("[data-step-preview-target='buttonColor']");
    var fontFamily = document.querySelector("[data-step-preview-target='fontFamily']");
    var fontSize = document.querySelector("[data-step-preview-target='fontSize']");
    var borderRadius = document.querySelector("[data-step-preview-target='borderRadius']");
    var tooltipBody = document.querySelector("[data-step-preview-target='tooltipBody']");

    if (previewTitle && title) previewTitle.textContent = title.value || "Step Title";
    if (previewBody && body) previewBody.textContent = body.value || "Step description goes here...";

    if (tooltipBody) {
      if (bgColor) tooltipBody.style.background = bgColor.value;
      if (fontFamily) tooltipBody.style.fontFamily = fontFamily.value;
      if (borderRadius) tooltipBody.style.borderRadius = borderRadius.value;
    }
    if (previewTitle && textColor) previewTitle.style.color = textColor.value;
    if (previewBody && textColor) previewBody.style.color = textColor.value;
    if (previewBody && fontSize) previewBody.style.fontSize = fontSize.value;
    if (previewButton && buttonColor) previewButton.style.background = buttonColor.value;
  }

  // Attach listeners to all form inputs
  form.querySelectorAll("input, textarea, select").forEach(function(el) {
    el.addEventListener("input", updatePreview);
    el.addEventListener("change", updatePreview);
  });
});

// === Segment Rules Controller ===
document.addEventListener("DOMContentLoaded", function() {
  var wrapper = document.querySelector("[data-controller='segment-rules']");
  if (!wrapper) return;

  var container = wrapper.querySelector("[data-segment-rules-target='container']");
  var output = wrapper.querySelector("[data-segment-rules-target='output']");
  var logicSelect = wrapper.querySelector("[data-segment-rules-target='logic']");
  var addButton = wrapper.querySelector("[data-action*='segment-rules#add']");

  function serialize() {
    var rows = container.querySelectorAll(".oor-segment-row");
    var conditions = Array.from(rows).map(function(row) {
      var op = row.querySelector(".oor-segment-op").value;
      var value = row.querySelector(".oor-segment-val").value;
      if (op === "in") value = value.split(",").map(function(v) { return v.trim(); });
      return { attribute: row.querySelector(".oor-segment-attr").value, operator: op, value: value };
    });
    var logic = logicSelect ? logicSelect.value : "and";
    output.value = JSON.stringify({ conditions: conditions, logic: logic });
  }

  function addConditionRow(condition) {
    var row = document.createElement("div");
    row.className = "oor-segment-row";
    row.style.cssText = "display:flex;gap:8px;margin-bottom:8px;align-items:center;";
    row.innerHTML =
      '<input type="text" placeholder="attribute" value="' + (condition.attribute || "") + '" class="oor-segment-attr" style="flex:1;padding:6px 8px;border:1px solid var(--oor-border);border-radius:4px;font-size:13px;">' +
      '<select class="oor-segment-op" style="padding:6px 8px;border:1px solid var(--oor-border);border-radius:4px;font-size:13px;">' +
        '<option value="eq"' + (condition.operator === "eq" ? " selected" : "") + '>equals</option>' +
        '<option value="not_eq"' + (condition.operator === "not_eq" ? " selected" : "") + '>not equals</option>' +
        '<option value="in"' + (condition.operator === "in" ? " selected" : "") + '>in</option>' +
        '<option value="gt"' + (condition.operator === "gt" ? " selected" : "") + '>greater than</option>' +
        '<option value="lt"' + (condition.operator === "lt" ? " selected" : "") + '>less than</option>' +
      '</select>' +
      '<input type="text" placeholder="value" value="' + (Array.isArray(condition.value) ? condition.value.join(", ") : (condition.value || "")) + '" class="oor-segment-val" style="flex:1;padding:6px 8px;border:1px solid var(--oor-border);border-radius:4px;font-size:13px;">' +
      '<button type="button" class="oor-segment-remove" style="background:none;border:none;color:var(--oor-danger);cursor:pointer;font-size:16px;">&times;</button>';

    row.querySelector(".oor-segment-remove").addEventListener("click", function() {
      row.remove();
      serialize();
    });
    row.querySelectorAll("input,select").forEach(function(el) {
      el.addEventListener("change", serialize);
    });
    container.appendChild(row);
    serialize();
  }

  function loadExisting() {
    var data;
    try { data = JSON.parse(output.value || "{}"); } catch(e) { data = {}; }
    if (data.conditions) {
      data.conditions.forEach(function(c) { addConditionRow(c); });
    }
    if (data.logic && logicSelect) logicSelect.value = data.logic;
  }

  if (addButton) {
    addButton.addEventListener("click", function(e) {
      e.preventDefault();
      addConditionRow({ attribute: "", operator: "eq", value: "" });
    });
  }

  if (logicSelect) {
    logicSelect.addEventListener("change", serialize);
  }

  loadExisting();
});

// === Sortable Controller ===
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

// === Selector Picker Controller ===
// Register on window directly (not inside DOMContentLoaded) so it survives Turbo Drive navigations
window.addEventListener("message", function(event) {
  if (event.data && event.data.type === "oor-selector-picked") {
    var input = document.querySelector("input[name='step[selector]']")
              || document.getElementById("step_selector");
    if (input) {
      input.value = event.data.selector;
      input.dispatchEvent(new Event("input"));
      input.dispatchEvent(new Event("change"));
    }
  }
});
