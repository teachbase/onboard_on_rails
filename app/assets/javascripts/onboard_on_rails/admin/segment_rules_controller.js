(() => {
  if (typeof Stimulus === "undefined") return;
  const application = Stimulus.Application.start();

  application.register("segment-rules", class extends Stimulus.Controller {
    static targets = ["container", "output", "logic"];

    connect() { this.loadExisting(); }

    loadExisting() {
      const data = JSON.parse(this.outputTarget.value || "{}");
      if (data.conditions) data.conditions.forEach(c => this.addConditionRow(c));
      if (data.logic && this.hasLogicTarget) this.logicTarget.value = data.logic;
    }

    add() { this.addConditionRow({ attribute: "", operator: "eq", value: "" }); }

    addConditionRow(condition) {
      const row = document.createElement("div");
      row.className = "oor-segment-row";
      row.style.cssText = "display:flex;gap:8px;margin-bottom:8px;align-items:center;";
      row.innerHTML = `
        <input type="text" placeholder="attribute" value="${condition.attribute}" class="oor-segment-attr" style="flex:1;padding:6px 8px;border:1px solid var(--oor-border);border-radius:4px;font-size:13px;">
        <select class="oor-segment-op" style="padding:6px 8px;border:1px solid var(--oor-border);border-radius:4px;font-size:13px;">
          <option value="eq" ${condition.operator==="eq"?"selected":""}>equals</option>
          <option value="not_eq" ${condition.operator==="not_eq"?"selected":""}>not equals</option>
          <option value="in" ${condition.operator==="in"?"selected":""}>in</option>
          <option value="gt" ${condition.operator==="gt"?"selected":""}>greater than</option>
          <option value="lt" ${condition.operator==="lt"?"selected":""}>less than</option>
        </select>
        <input type="text" placeholder="value" value="${Array.isArray(condition.value)?condition.value.join(", "):condition.value}" class="oor-segment-val" style="flex:1;padding:6px 8px;border:1px solid var(--oor-border);border-radius:4px;font-size:13px;">
        <button type="button" data-action="click->segment-rules#removeRow" style="background:none;border:none;color:var(--oor-danger);cursor:pointer;font-size:16px;">&times;</button>
      `;
      row.querySelectorAll("input,select").forEach(el => el.addEventListener("change", () => this.serialize()));
      this.containerTarget.appendChild(row);
      this.serialize();
    }

    removeRow(event) {
      event.target.closest(".oor-segment-row").remove();
      this.serialize();
    }

    serialize() {
      const rows = this.containerTarget.querySelectorAll(".oor-segment-row");
      const conditions = Array.from(rows).map(row => {
        const op = row.querySelector(".oor-segment-op").value;
        let value = row.querySelector(".oor-segment-val").value;
        if (op === "in") value = value.split(",").map(v => v.trim());
        return { attribute: row.querySelector(".oor-segment-attr").value, operator: op, value };
      });
      const logic = this.hasLogicTarget ? this.logicTarget.value : "and";
      this.outputTarget.value = JSON.stringify({ conditions, logic });
    }
  });
})();
