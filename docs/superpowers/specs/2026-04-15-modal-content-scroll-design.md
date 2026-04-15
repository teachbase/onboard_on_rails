# Modal content scroll on overflow

## Problem

When a tour step uses Modal theme and the content doesn't fit (e.g., custom HTML with large content), the content is cut off and cannot be fully viewed.

## Decision

Add `max-height: min(500px, 70vh)` and `overflow: auto` to the modal's content area.

## Design

### Change location

`app/assets/stylesheets/onboard_on_rails/client.css` — after line 182 (`.oor-theme-modal` section)

### New CSS

```css
.oor-theme-modal .oor-step-content {
  max-height: min(500px, 70vh);
  overflow: auto;
}
```

### Result

- Content scrolls when overflowing
- Footer with navigation buttons stays visible
- On small screens (70vh < 500px), height adapts automatically
- Other themes (tooltip, banner, slideout) unaffected
