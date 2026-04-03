window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.PositioningEngine = {
  MARGIN: 12,
  position(tooltip, targetEl, placement) {
    const targetRect = targetEl.getBoundingClientRect();
    const tooltipRect = tooltip.getBoundingClientRect();
    const scrollX = window.scrollX;
    const scrollY = window.scrollY;
    let top, left;
    const resolved = this.resolvePlacement(placement, targetRect, tooltipRect);
    switch (resolved) {
      case "top":
        top = targetRect.top + scrollY - tooltipRect.height - this.MARGIN;
        left = targetRect.left + scrollX + (targetRect.width - tooltipRect.width) / 2;
        break;
      case "bottom":
        top = targetRect.bottom + scrollY + this.MARGIN;
        left = targetRect.left + scrollX + (targetRect.width - tooltipRect.width) / 2;
        break;
      case "left":
        top = targetRect.top + scrollY + (targetRect.height - tooltipRect.height) / 2;
        left = targetRect.left + scrollX - tooltipRect.width - this.MARGIN;
        break;
      case "right":
        top = targetRect.top + scrollY + (targetRect.height - tooltipRect.height) / 2;
        left = targetRect.right + scrollX + this.MARGIN;
        break;
      case "center":
        top = (window.innerHeight - tooltipRect.height) / 2 + scrollY;
        left = (window.innerWidth - tooltipRect.width) / 2 + scrollX;
        break;
    }
    left = Math.max(this.MARGIN, Math.min(left, window.innerWidth + scrollX - tooltipRect.width - this.MARGIN));
    top = Math.max(this.MARGIN, top);
    tooltip.style.position = "absolute";
    tooltip.style.top = top + "px";
    tooltip.style.left = left + "px";
    tooltip.dataset.placement = resolved;
  },
  resolvePlacement(preferred, targetRect, tooltipRect) {
    if (preferred === "center") return "center";
    const space = {
      top: targetRect.top - this.MARGIN,
      bottom: window.innerHeight - targetRect.bottom - this.MARGIN,
      left: targetRect.left - this.MARGIN,
      right: window.innerWidth - targetRect.right - this.MARGIN
    };
    const needed = { top: tooltipRect.height, bottom: tooltipRect.height, left: tooltipRect.width, right: tooltipRect.width };
    if (space[preferred] >= needed[preferred]) return preferred;
    const opposite = { top: "bottom", bottom: "top", left: "right", right: "left" };
    if (space[opposite[preferred]] >= needed[opposite[preferred]]) return opposite[preferred];
    return Object.entries(space).sort((a, b) => b[1] - a[1])[0][0];
  },
  getClipPath(targetEl) {
    const rect = targetEl.getBoundingClientRect();
    const pad = 4;
    const x = rect.left - pad, y = rect.top - pad;
    const w = rect.width + pad * 2, h = rect.height + pad * 2;
    const r = 4;
    return `polygon(0% 0%, 100% 0%, 100% 100%, 0% 100%, 0% 0%, ${x}px ${y+r}px, ${x+r}px ${y}px, ${x+w-r}px ${y}px, ${x+w}px ${y+r}px, ${x+w}px ${y+h-r}px, ${x+w-r}px ${y+h}px, ${x+r}px ${y+h}px, ${x}px ${y+h-r}px, ${x}px ${y+r}px)`;
  },
  scrollIntoView(targetEl) {
    const rect = targetEl.getBoundingClientRect();
    if (rect.top < 0 || rect.bottom > window.innerHeight) {
      targetEl.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }
};
