# Interactive page when overlay is disabled

## Problem

When `overlay_enabled: false` on a tour, the overlay background becomes transparent but the `div.oor-overlay` element still covers the entire page with `pointer-events: auto`. The page is visually unobscured but completely unresponsive to user interaction (clicks, scrolling, text selection).

## Decision

Add `pointer-events: none` to the overlay element when `overlayEnabled === false`.

## Design

### Change location

`app/assets/javascripts/onboard_on_rails/client.js` — `TourRenderer.createOverlay()` method (lines 358-366).

### Current code

```js
createOverlay(targetEl, overlayEnabled) {
  this.overlay = document.createElement("div");
  this.overlay.className = "oor-overlay";
  if (overlayEnabled === false) {
    this.overlay.style.background = "transparent";
  }
  if (targetEl) this.overlay.style.clipPath = OnboardOnRails.PositioningEngine.getClipPath(targetEl);
  document.body.appendChild(this.overlay);
},
```

### New behavior

When `overlayEnabled === false`:
- `this.overlay.style.background = "transparent"` (existing)
- `this.overlay.style.pointerEvents = "none"` (new)

### Why this works

1. **Page becomes interactive** — `pointer-events: none` lets all clicks, scrolls, and other events pass through the overlay to the page beneath.
2. **Tooltip stays clickable** — `.oor-tour-step` has `z-index: 10001` (above overlay's `10000`) and retains the default `pointer-events: auto`. Tour navigation buttons remain functional.
3. **Tooltip follows target on scroll** — a scroll listener already exists (line 331) that calls `PositioningEngine.position()` on scroll. Currently it only fires on programmatic scroll because the overlay blocks user scrolling. With `pointer-events: none`, user scroll events reach the page and trigger repositioning.
4. **Click outside does nothing** — clicks on the page interact with the page, not the tour. The tour stays open until the user explicitly advances or dismisses it via tour buttons.
5. **No CSS changes needed** — the overlay element stays in the DOM (no refactoring of cleanup/clipPath logic), just becomes non-blocking.

### What does NOT change

- Behavior when `overlay_enabled: true` — unchanged, overlay blocks interaction as before.
- Highlighted target element z-index and styling — unchanged.
- Resize/scroll listener lifecycle — unchanged.
- Cleanup logic — unchanged, overlay is still removed from DOM on tour end.

### Testing

- Manual: create a tour with `overlay_enabled: false`, verify page is scrollable and clickable, tooltip follows target element, tour buttons work.
- RSpec: no backend changes, no new specs needed.
