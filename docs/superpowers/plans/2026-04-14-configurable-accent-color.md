# Configurable Accent Color Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hardcoded purple accent (`#6c5ce7`) with a configurable `accent_color` (default `#2d3436`) that drives admin panel theme and client-side tour button defaults.

**Architecture:** Single `accent_color` attr in `Configuration` with Ruby-computed derived colors (dark, light, rgba). Admin layout injects CSS variables via `<style>` block. Client-side gets the default via meta tag. All hardcoded references replaced with config lookups.

**Tech Stack:** Ruby, ERB, vanilla CSS/JS. No new dependencies.

---

### Task 1: Configuration — accent_color with derived colors

**Files:**
- Modify: `lib/onboard_on_rails/configuration.rb`
- Create: `spec/lib/configuration_spec.rb`

- [ ] **Step 1: Write the failing test**

Create `spec/lib/configuration_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Configuration do
  subject(:config) { described_class.new }

  describe "#accent_color" do
    it "defaults to #2d3436" do
      expect(config.accent_color).to eq("#2d3436")
    end

    it "accepts custom color" do
      config.accent_color = "#ff6600"
      expect(config.accent_color).to eq("#ff6600")
    end
  end

  describe "#accent_color_dark" do
    it "returns a darker shade of the accent color" do
      config.accent_color = "#6c5ce7"
      dark = config.accent_color_dark
      expect(dark).to match(/\A#[0-9a-f]{6}\z/i)
      # Should be darker than original
      r, g, b = dark[1..2].to_i(16), dark[3..4].to_i(16), dark[5..6].to_i(16)
      expect(r).to be < 0x6c
      expect(g).to be < 0x5c
      expect(b).to be < 0xe7
    end
  end

  describe "#accent_color_light" do
    it "returns a lighter shade of the accent color" do
      config.accent_color = "#2d3436"
      light = config.accent_color_light
      expect(light).to match(/\A#[0-9a-f]{6}\z/i)
      r, g, b = light[1..2].to_i(16), light[3..4].to_i(16), light[5..6].to_i(16)
      expect(r).to be > 0x2d
      expect(g).to be > 0x34
      expect(b).to be > 0x36
    end
  end

  describe "#accent_color_rgba" do
    it "returns rgba string with given alpha" do
      config.accent_color = "#2d3436"
      expect(config.accent_color_rgba(0.15)).to eq("rgba(45, 52, 54, 0.15)")
    end

    it "works with bright colors" do
      config.accent_color = "#ff0000"
      expect(config.accent_color_rgba(0.5)).to eq("rgba(255, 0, 0, 0.5)")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/lib/configuration_spec.rb`
Expected: FAIL — `accent_color` method not defined, test file may need directory creation.

- [ ] **Step 3: Write the implementation**

Replace `lib/onboard_on_rails/configuration.rb` with:

```ruby
module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :user_attributes, :current_user_method, :accent_color

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @user_attributes = ->(user) { {} }
      @current_user_method = :current_user
      @accent_color = "#2d3436"
    end

    def accent_color_dark
      adjust_brightness(accent_color, -0.15)
    end

    def accent_color_light
      adjust_brightness(accent_color, 0.40)
    end

    def accent_color_rgba(alpha)
      r, g, b = hex_to_rgb(accent_color)
      "rgba(#{r}, #{g}, #{b}, #{alpha})"
    end

    private

    def hex_to_rgb(hex)
      hex = hex.delete("#")
      [hex[0..1].to_i(16), hex[2..3].to_i(16), hex[4..5].to_i(16)]
    end

    def adjust_brightness(hex, factor)
      r, g, b = hex_to_rgb(hex)
      if factor > 0
        r = (r + (255 - r) * factor).round.clamp(0, 255)
        g = (g + (255 - g) * factor).round.clamp(0, 255)
        b = (b + (255 - b) * factor).round.clamp(0, 255)
      else
        r = (r * (1 + factor)).round.clamp(0, 255)
        g = (g * (1 + factor)).round.clamp(0, 255)
        b = (b * (1 + factor)).round.clamp(0, 255)
      end
      "#%02x%02x%02x" % [r, g, b]
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/lib/configuration_spec.rb`
Expected: All 5 examples PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/onboard_on_rails/configuration.rb spec/lib/configuration_spec.rb
git commit -m "feat: add accent_color to Configuration with derived color helpers"
```

---

### Task 2: Admin CSS — update defaults and replace hardcoded rgba

**Files:**
- Modify: `app/assets/stylesheets/onboard_on_rails/admin.css`

- [ ] **Step 1: Update `:root` CSS variables to new defaults and add shadow/bg vars**

In `app/assets/stylesheets/onboard_on_rails/admin.css`, replace the `:root` block (lines 6–24):

Old:
```css
:root {
  --oor-primary: #6c5ce7;
  --oor-primary-dark: #5a4bd1;
  --oor-primary-light: #a29bfe;
```

New:
```css
:root {
  --oor-primary: #2d3436;
  --oor-primary-dark: #262d2f;
  --oor-primary-light: #7e8587;
  --oor-primary-shadow: rgba(45, 52, 54, 0.15);
  --oor-primary-bg: rgba(45, 52, 54, 0.12);
```

- [ ] **Step 2: Replace hardcoded rgba in focus box-shadow**

In `admin.css` line 341, replace:

Old:
```css
  box-shadow: 0 0 0 3px rgba(108, 92, 231, 0.15);
```

New:
```css
  box-shadow: 0 0 0 3px var(--oor-primary-shadow);
```

- [ ] **Step 3: Replace hardcoded rgba in stat-card icon**

In `admin.css` line 820, replace:

Old:
```css
.oor-stat-card__icon--started {
  background: rgba(108, 92, 231, 0.12);
  color: var(--oor-primary);
}
```

New:
```css
.oor-stat-card__icon--started {
  background: var(--oor-primary-bg);
  color: var(--oor-primary);
}
```

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/onboard_on_rails/admin.css
git commit -m "fix: replace hardcoded purple with neutral accent color in admin CSS"
```

---

### Task 3: Admin layout — inject CSS variables from config

**Files:**
- Modify: `app/views/layouts/onboard_on_rails/admin.html.erb`

- [ ] **Step 1: Add `<style>` block after the stylesheet link tags**

In `app/views/layouts/onboard_on_rails/admin.html.erb`, after line 8 (`<%= csrf_meta_tags %>`), insert:

```erb
  <style>
    :root {
      --oor-primary: <%= OnboardOnRails.configuration.accent_color %>;
      --oor-primary-dark: <%= OnboardOnRails.configuration.accent_color_dark %>;
      --oor-primary-light: <%= OnboardOnRails.configuration.accent_color_light %>;
      --oor-primary-shadow: <%= OnboardOnRails.configuration.accent_color_rgba(0.15) %>;
      --oor-primary-bg: <%= OnboardOnRails.configuration.accent_color_rgba(0.12) %>;
    }
  </style>
```

- [ ] **Step 2: Commit**

```bash
git add app/views/layouts/onboard_on_rails/admin.html.erb
git commit -m "feat: inject accent color CSS variables from config into admin layout"
```

---

### Task 4: Admin views — replace hardcoded `#6c5ce7` fallbacks

**Files:**
- Modify: `app/views/onboard_on_rails/admin/tours/_form.html.erb:94-96`
- Modify: `app/views/onboard_on_rails/admin/steps/_form.html.erb:138-139`
- Modify: `app/views/onboard_on_rails/admin/steps/_preview.html.erb:28`

- [ ] **Step 1: Update tour form**

In `app/views/onboard_on_rails/admin/tours/_form.html.erb`, replace lines 94-95:

Old:
```erb
      <input type="color" name="tour[style_overrides][button_color]" value="<%= tour.style_overrides&.dig('button_color') || '#6c5ce7' %>">
      <input type="text" name="tour[style_overrides][button_color]" value="<%= tour.style_overrides&.dig('button_color') || '#6c5ce7' %>" placeholder="#6c5ce7">
```

New:
```erb
      <input type="color" name="tour[style_overrides][button_color]" value="<%= tour.style_overrides&.dig('button_color') || OnboardOnRails.configuration.accent_color %>">
      <input type="text" name="tour[style_overrides][button_color]" value="<%= tour.style_overrides&.dig('button_color') || OnboardOnRails.configuration.accent_color %>" placeholder="<%= OnboardOnRails.configuration.accent_color %>">
```

- [ ] **Step 2: Update step form**

In `app/views/onboard_on_rails/admin/steps/_form.html.erb`, replace lines 138-139:

Old:
```erb
      <input type="color" name="step[style_overrides][button_color]" value="<%= step.style_overrides&.dig('button_color') || '#6c5ce7' %>">
      <input type="text" name="step[style_overrides][button_color]" value="<%= step.style_overrides&.dig('button_color') || '#6c5ce7' %>" placeholder="#6c5ce7">
```

New:
```erb
      <input type="color" name="step[style_overrides][button_color]" value="<%= step.style_overrides&.dig('button_color') || OnboardOnRails.configuration.accent_color %>">
      <input type="text" name="step[style_overrides][button_color]" value="<%= step.style_overrides&.dig('button_color') || OnboardOnRails.configuration.accent_color %>" placeholder="<%= OnboardOnRails.configuration.accent_color %>">
```

- [ ] **Step 3: Update step preview**

In `app/views/onboard_on_rails/admin/steps/_preview.html.erb`, replace line 28:

Old:
```erb
    button_color = step.style_overrides&.dig('button_color') || '#6c5ce7'
```

New:
```erb
    button_color = step.style_overrides&.dig('button_color') || OnboardOnRails.configuration.accent_color
```

- [ ] **Step 4: Commit**

```bash
git add app/views/onboard_on_rails/admin/tours/_form.html.erb app/views/onboard_on_rails/admin/steps/_form.html.erb app/views/onboard_on_rails/admin/steps/_preview.html.erb
git commit -m "fix: use configured accent_color as default button_color in admin forms"
```

---

### Task 5: Selector picker — replace hardcoded colors

**Files:**
- Modify: `app/views/onboard_on_rails/selector_picker/show.html.erb:20,43`

- [ ] **Step 1: Replace toolbar button color**

In `app/views/onboard_on_rails/selector_picker/show.html.erb`, replace line 20:

Old:
```html
    .oor-picker-toolbar__btn--confirm { background: #6c5ce7; color: white; }
```

New:
```erb
    .oor-picker-toolbar__btn--confirm { background: <%= OnboardOnRails.configuration.accent_color %>; color: white; }
```

- [ ] **Step 2: Replace highlight outline color**

In the same file, replace the string in line 43:

Old:
```javascript
      style.textContent = ".oor-picker-highlight { outline: 3px solid #6c5ce7 !important; outline-offset: 2px !important; cursor: crosshair !important; }";
```

New:
```erb
      style.textContent = ".oor-picker-highlight { outline: 3px solid <%= OnboardOnRails.configuration.accent_color %> !important; outline-offset: 2px !important; cursor: crosshair !important; }";
```

- [ ] **Step 3: Commit**

```bash
git add app/views/onboard_on_rails/selector_picker/show.html.erb
git commit -m "fix: use configured accent_color in selector picker"
```

---

### Task 6: Client-side — meta tag + JS + CSS default

**Files:**
- Modify: `app/helpers/onboard_on_rails/meta_tags_helper.rb:10-12`
- Modify: `app/assets/javascripts/onboard_on_rails/client.js:24` (client CSS var line)
- Modify: `app/assets/stylesheets/onboard_on_rails/client.css:24`

- [ ] **Step 1: Add accent-color meta tag**

In `app/helpers/onboard_on_rails/meta_tags_helper.rb`, replace lines 10-12:

Old:
```ruby
      tag.meta(name: "onboard-on-rails-user-id", content: user.id) +
        tag.meta(name: "onboard-on-rails-mount-path", content: mount_path) +
        tag.meta(name: "csrf-token", content: form_authenticity_token)
```

New:
```ruby
      tag.meta(name: "onboard-on-rails-user-id", content: user.id) +
        tag.meta(name: "onboard-on-rails-mount-path", content: mount_path) +
        tag.meta(name: "onboard-on-rails-accent-color", content: OnboardOnRails.configuration.accent_color) +
        tag.meta(name: "csrf-token", content: form_authenticity_token)
```

- [ ] **Step 2: Update client CSS default**

In `app/assets/stylesheets/onboard_on_rails/client.css`, replace line 24:

Old:
```css
  --oor-step-btn-bg: #4361ee;
```

New:
```css
  --oor-step-btn-bg: #2d3436;
```

- [ ] **Step 3: Read accent color meta tag in TourManager.init**

In `app/assets/javascripts/onboard_on_rails/client.js`, in the `TourManager.init()` method (around line 405), replace:

Old:
```javascript
  init() {
    if (!OnboardOnRails.ApiClient.getUserId()) return;
    this.sessionId = this.getOrCreateSessionId();
    this.loadTour();
    OnboardOnRails.DOMObserver.start(() => this.loadTour());
  },
```

New:
```javascript
  init() {
    if (!OnboardOnRails.ApiClient.getUserId()) return;
    var accentMeta = document.querySelector('meta[name="onboard-on-rails-accent-color"]');
    if (accentMeta && accentMeta.content) {
      document.documentElement.style.setProperty("--oor-step-btn-bg", accentMeta.content);
    }
    this.sessionId = this.getOrCreateSessionId();
    this.loadTour();
    OnboardOnRails.DOMObserver.start(() => this.loadTour());
  },
```

- [ ] **Step 4: Commit**

```bash
git add app/helpers/onboard_on_rails/meta_tags_helper.rb app/assets/stylesheets/onboard_on_rails/client.css app/assets/javascripts/onboard_on_rails/client.js
git commit -m "feat: propagate accent_color to client-side via meta tag"
```

---

### Task 7: Full test suite — verify no regressions

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `bundle exec rspec`
Expected: All examples pass, including the new `configuration_spec.rb`.

- [ ] **Step 2: If any failures, fix them**

Likely causes:
- Existing specs that assert hardcoded `#6c5ce7` in rendered HTML — update to `#2d3436` or `OnboardOnRails.configuration.accent_color`.
- Meta tags helper specs that check exact output — add the new `accent-color` meta tag to expectations.

- [ ] **Step 3: Commit any fixes**

```bash
git add -A
git commit -m "fix: update specs for new accent_color default"
```
