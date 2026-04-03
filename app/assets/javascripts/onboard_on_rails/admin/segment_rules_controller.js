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
