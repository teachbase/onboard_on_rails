(() => {
  if (typeof Stimulus === "undefined") return;
  const application = Stimulus.Application.start();

  application.register("step-preview", class extends Stimulus.Controller {
    static targets = [
      "title", "body", "tooltip", "tooltipBody",
      "previewTitle", "previewBody", "previewButton",
      "bgColor", "textColor", "fontFamily", "fontSize",
      "borderRadius", "buttonColor", "highlight"
    ];

    update() {
      if (this.hasTitleTarget && this.hasPreviewTitleTarget) {
        this.previewTitleTarget.textContent = this.titleTarget.value || "Step Title";
      }
      if (this.hasBodyTarget && this.hasPreviewBodyTarget) {
        this.previewBodyTarget.textContent = this.bodyTarget.value || "Step description goes here...";
      }
      if (this.hasTooltipBodyTarget) {
        if (this.hasBgColorTarget) this.tooltipBodyTarget.style.background = this.bgColorTarget.value;
        if (this.hasTextColorTarget) {
          this.previewTitleTarget.style.color = this.textColorTarget.value;
          this.previewBodyTarget.style.color = this.textColorTarget.value;
        }
        if (this.hasFontFamilyTarget) this.tooltipBodyTarget.style.fontFamily = this.fontFamilyTarget.value;
        if (this.hasFontSizeTarget) this.previewBodyTarget.style.fontSize = this.fontSizeTarget.value;
        if (this.hasBorderRadiusTarget) this.tooltipBodyTarget.style.borderRadius = this.borderRadiusTarget.value;
      }
      if (this.hasButtonColorTarget && this.hasPreviewButtonTarget) {
        this.previewButtonTarget.style.background = this.buttonColorTarget.value;
      }
    }
  });
})();
