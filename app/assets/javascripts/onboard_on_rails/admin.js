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

  var availableAttributes = [];
  var operatorLabels = {};
  var placeholders = {};

  try { availableAttributes = JSON.parse(wrapper.getAttribute("data-available-attributes") || "[]"); } catch(e) {}
  try { operatorLabels = JSON.parse(wrapper.getAttribute("data-operator-labels") || "{}"); } catch(e) {}
  try { placeholders = JSON.parse(wrapper.getAttribute("data-placeholders") || "{}"); } catch(e) {}

  var OPERATORS_BY_TYPE = {
    string:  ["eq", "not_eq", "in", "not_in", "starts_with", "ends_with", "contains", "not_contains", "matches", "length_gt", "length_lt"],
    number:  ["eq", "not_eq", "in", "not_in", "gt", "lt", "gte", "lte"],
    boolean: ["eq"]
  };

  function findAttr(key) {
    for (var i = 0; i < availableAttributes.length; i++) {
      if (availableAttributes[i].key === key) return availableAttributes[i];
    }
    return null;
  }

  function serialize() {
    var rows = container.querySelectorAll(".oor-segment-row");
    var conditions = Array.from(rows).map(function(row) {
      var op = row.querySelector(".oor-segment-op").value;
      var val = row.querySelector(".oor-segment-val").value;
      if (op === "in" || op === "not_in") {
        val = val.split(",").map(function(v) { return v.trim(); });
      }
      return {
        attribute: row.querySelector(".oor-segment-attr").value,
        operator: op,
        value: val
      };
    });
    var logic = logicSelect ? logicSelect.value : "and";
    output.value = JSON.stringify({ conditions: conditions, logic: logic });
  }

  function buildAttrSelect(selectedKey) {
    var html = "";
    for (var i = 0; i < availableAttributes.length; i++) {
      var a = availableAttributes[i];
      var sel = a.key === selectedKey ? " selected" : "";
      html += '<option value="' + a.key + '"' + sel + '>' + a.label + '</option>';
    }
    return html;
  }

  function buildOpSelect(type, selectedOp) {
    var ops = OPERATORS_BY_TYPE[type] || OPERATORS_BY_TYPE.string;
    var html = "";
    for (var i = 0; i < ops.length; i++) {
      var op = ops[i];
      var label = operatorLabels[op] || op;
      var sel = op === selectedOp ? " selected" : "";
      html += '<option value="' + op + '"' + sel + '>' + label + '</option>';
    }
    return html;
  }

  function buildValueInput(attrDef, operator, value) {
    if (operator === "eq" && attrDef && attrDef.type === "boolean") {
      return '<select class="oor-segment-val oor-form-control" style="flex:1;">' +
        '<option value="true"' + (value === "true" ? " selected" : "") + '>' + (placeholders.boolean_true || "true") + '</option>' +
        '<option value="false"' + (value !== "true" ? " selected" : "") + '>' + (placeholders.boolean_false || "false") + '</option>' +
        '</select>';
    }
    if ((operator === "eq" || operator === "not_eq") && attrDef && attrDef.values && attrDef.values.length > 0) {
      var html = '<select class="oor-segment-val oor-form-control" style="flex:1;">';
      for (var i = 0; i < attrDef.values.length; i++) {
        var v = attrDef.values[i];
        var sel = v === value ? " selected" : "";
        html += '<option value="' + v + '"' + sel + '>' + v + '</option>';
      }
      html += '</select>';
      return html;
    }
    var placeholder = placeholders.value || "value";
    if (operator === "in" || operator === "not_in") placeholder = placeholders.in_values || "values separated by comma";
    if (operator === "matches") placeholder = placeholders.regex || "regular expression";
    var displayValue = Array.isArray(value) ? value.join(", ") : (value || "");
    return '<input type="text" placeholder="' + placeholder + '" value="' + displayValue + '" class="oor-segment-val oor-form-control" style="flex:1;">';
  }

  function addConditionRow(condition) {
    var attrKey = condition.attribute || (availableAttributes[0] ? availableAttributes[0].key : "");
    var attrDef = findAttr(attrKey);
    var type = attrDef ? attrDef.type : "string";
    var operator = condition.operator || "eq";

    var row = document.createElement("div");
    row.className = "oor-segment-row";

    row.innerHTML =
      '<div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">' +
        '<select class="oor-segment-attr oor-form-control" style="flex:1;min-width:120px;">' + buildAttrSelect(attrKey) + '</select>' +
        '<select class="oor-segment-op oor-form-control" style="flex:1;min-width:120px;">' + buildOpSelect(type, operator) + '</select>' +
        buildValueInput(attrDef, operator, Array.isArray(condition.value) ? condition.value.join(", ") : (condition.value || "")) +
        '<button type="button" class="oor-segment-remove oor-btn oor-btn--sm oor-btn--danger" style="flex-shrink:0;">&times;</button>' +
      '</div>' +
      (attrDef && attrDef.description ? '<div class="oor-segment-description">' + attrDef.description + '</div>' : '');

    row.querySelector(".oor-segment-remove").addEventListener("click", function() {
      row.remove();
      serialize();
    });

    var attrSelect = row.querySelector(".oor-segment-attr");
    attrSelect.addEventListener("change", function() {
      var newAttrDef = findAttr(attrSelect.value);
      var newType = newAttrDef ? newAttrDef.type : "string";
      var opSelect = row.querySelector(".oor-segment-op");
      opSelect.innerHTML = buildOpSelect(newType, "eq");
      var oldValEl = row.querySelector(".oor-segment-val");
      var temp = document.createElement("div");
      temp.innerHTML = buildValueInput(newAttrDef, "eq", "");
      oldValEl.parentNode.replaceChild(temp.firstChild, oldValEl);
      var descEl = row.querySelector(".oor-segment-description");
      if (descEl) descEl.remove();
      if (newAttrDef && newAttrDef.description) {
        var newDesc = document.createElement("div");
        newDesc.className = "oor-segment-description";
        newDesc.textContent = newAttrDef.description;
        row.appendChild(newDesc);
      }
      bindRowEvents(row);
      serialize();
    });

    var opSelect = row.querySelector(".oor-segment-op");
    opSelect.addEventListener("change", function() {
      var currentAttrDef = findAttr(attrSelect.value);
      var oldValEl = row.querySelector(".oor-segment-val");
      var temp = document.createElement("div");
      temp.innerHTML = buildValueInput(currentAttrDef, opSelect.value, "");
      oldValEl.parentNode.replaceChild(temp.firstChild, oldValEl);
      bindRowEvents(row);
      serialize();
    });

    bindRowEvents(row);
    container.appendChild(row);
    serialize();
  }

  function bindRowEvents(row) {
    row.querySelectorAll(".oor-segment-val, .oor-segment-op, .oor-segment-attr").forEach(function(el) {
      el.removeEventListener("change", serialize);
      el.removeEventListener("input", serialize);
      el.addEventListener("change", serialize);
      el.addEventListener("input", serialize);
    });
  }

  function loadExisting() {
    var data;
    try { data = JSON.parse(output.value || "{}"); } catch(e) { data = {}; }
    if (data.conditions && data.conditions.length > 0) {
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
