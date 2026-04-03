document.addEventListener("DOMContentLoaded", function() {
  // Listen for selector picked messages from the picker popup
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
});
