document.addEventListener("DOMContentLoaded", function() {
  var wrapper = document.querySelector("[data-controller='selector-picker']");
  if (!wrapper) return;

  var input = wrapper.querySelector("[data-selector-picker-target='input']");

  function handleMessage(event) {
    if (event.data && event.data.type === "oor-selector-picked" && input) {
      input.value = event.data.selector;
      input.dispatchEvent(new Event("input"));
    }
  }

  window.addEventListener("message", handleMessage);
});
