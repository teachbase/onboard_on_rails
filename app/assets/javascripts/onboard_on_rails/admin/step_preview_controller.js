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
