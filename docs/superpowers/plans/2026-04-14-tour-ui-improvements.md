# Tour UI Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 4 UI improvements: overlay toggle, step min-width, single-step nav hiding, configurable default font.

**Architecture:** Each feature is independent — a migration or config change, an admin form update, a client-side JS/CSS change, and locale entries. All follow existing patterns.

**Tech Stack:** Ruby on Rails 7.0+, vanilla JS, Sprockets, PostgreSQL (jsonb), RSpec + FactoryBot.

---

### Task 1: Hide navigation for single-step tours

**Files:**
- Modify: `app/assets/javascripts/onboard_on_rails/client.js:375-378`

- [ ] **Step 1: Modify createTooltip to hide navigation when totalSteps === 1**

In `app/assets/javascripts/onboard_on_rails/client.js`, replace lines 375-378:

```javascript
        ${totalSteps > 5
          ? `<div class="oor-step-counter">${stepIndex + 1} / ${totalSteps}</div>`
          : `<div class="oor-step-dots">${tour.steps.map((_, i) => `<span class="oor-dot ${i === stepIndex ? 'oor-dot--active' : ''}"></span>`).join("")}</div>`
        }
```

with:

```javascript
        ${totalSteps > 1
          ? (totalSteps > 5
            ? `<div class="oor-step-counter">${stepIndex + 1} / ${totalSteps}</div>`
            : `<div class="oor-step-dots">${tour.steps.map((_, i) => `<span class="oor-dot ${i === stepIndex ? 'oor-dot--active' : ''}"></span>`).join("")}</div>`)
          : ''
        }
```

- [ ] **Step 2: Verify manually**

Start the dev server and create a tour with a single step. Confirm no dots/counter appear. Then add a second step and confirm dots appear.

```bash
cd spec/dummy && RAILS_ENV=development bin/rails server
```

- [ ] **Step 3: Commit**

```bash
git add app/assets/javascripts/onboard_on_rails/client.js
git commit -m "fix: hide step navigation for single-step tours"
```

---

### Task 2: Add overlay_enabled toggle to tours

**Files:**
- Create: `db/migrate/20260414000001_add_overlay_enabled_to_onboard_on_rails_tours.rb`
- Modify: `app/controllers/onboard_on_rails/admin/tours_controller.rb:61-66`
- Modify: `app/views/onboard_on_rails/admin/tours/_form.html.erb:89`
- Modify: `app/controllers/onboard_on_rails/api/tours_controller.rb:27-34`
- Modify: `app/assets/javascripts/onboard_on_rails/client.js:357-361`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/ru.yml`
- Test: `spec/models/onboard_on_rails/tour_spec.rb`
- Test: `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb`

- [ ] **Step 1: Write the failing test for overlay_enabled default**

Add to `spec/models/onboard_on_rails/tour_spec.rb` inside the `describe "validations"` block, after the `device_type` tests (after line 46):

```ruby
    it "defaults overlay_enabled to true" do
      tour = build(:tour)
      expect(tour.overlay_enabled).to eq(true)
    end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bundle exec rspec spec/models/onboard_on_rails/tour_spec.rb
```

Expected: FAIL — `overlay_enabled` column doesn't exist yet.

- [ ] **Step 3: Create migration**

Create `db/migrate/20260414000001_add_overlay_enabled_to_onboard_on_rails_tours.rb`:

```ruby
class AddOverlayEnabledToOnboardOnRailsTours < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_tours, :overlay_enabled, :boolean, default: true, null: false
  end
end
```

- [ ] **Step 4: Run migration and test**

```bash
cd spec/dummy && bin/rails db:migrate RAILS_ENV=test && cd ../..
bundle exec rspec spec/models/onboard_on_rails/tour_spec.rb
```

Expected: PASS

- [ ] **Step 5: Add overlay_enabled to tour_params**

In `app/controllers/onboard_on_rails/admin/tours_controller.rb`, modify the `tour_params` method. Change line 62:

```ruby
          :name, :description, :status, :trigger_type, :trigger_event,
          :frequency, :theme, :priority, :schedule_start, :schedule_end,
          :ab_test_id, :ab_test_group, :device_type,
```

to:

```ruby
          :name, :description, :status, :trigger_type, :trigger_event,
          :frequency, :theme, :priority, :schedule_start, :schedule_end,
          :ab_test_id, :ab_test_group, :device_type, :overlay_enabled,
```

- [ ] **Step 6: Add checkbox to tour form**

In `app/views/onboard_on_rails/admin/tours/_form.html.erb`, add after the theme field (after line 59) and before the priority field:

```erb
  <div class="oor-form-group">
    <label>
      <%= f.check_box :overlay_enabled %>
      <%= t("onboard_on_rails.admin.tours.form.labels.overlay_enabled") %>
    </label>
    <div class="oor-form-hint"><%= t("onboard_on_rails.admin.tours.form.hints.overlay_enabled") %></div>
  </div>
```

- [ ] **Step 7: Add locale entries**

In `config/locales/en.yml`, add under `labels:` (after `device_type:` line 65):

```yaml
            overlay_enabled: "Show backdrop overlay"
```

And under `hints:` (after `button_color:` line 76):

```yaml
            overlay_enabled: "When enabled, a dark overlay covers the page behind the tour step."
```

In `config/locales/ru.yml`, add under `labels:` (after `device_type:` line 126):

```yaml
            overlay_enabled: "Затемнение фона"
```

And under `hints:` (after `button_color:` line 137):

```yaml
            overlay_enabled: "Затемняет страницу позади шага тура."
```

- [ ] **Step 8: Add overlay_enabled to API serialization**

In `app/controllers/onboard_on_rails/api/tours_controller.rb`, modify `serialize_tour` method. Add `overlay_enabled` to the hash (after `style_overrides` on line 31):

```ruby
          overlay_enabled: tour.overlay_enabled,
```

- [ ] **Step 9: Update client JS to respect overlay_enabled**

In `app/assets/javascripts/onboard_on_rails/client.js`, modify `createOverlay` method (lines 357-361). Replace:

```javascript
  createOverlay(targetEl) {
    this.overlay = document.createElement("div");
    this.overlay.className = "oor-overlay";
    if (targetEl) this.overlay.style.clipPath = OnboardOnRails.PositioningEngine.getClipPath(targetEl);
    document.body.appendChild(this.overlay);
  },
```

with:

```javascript
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

- [ ] **Step 10: Pass overlay_enabled from show() to createOverlay()**

In the same file, modify the `show` method (line 319). Replace:

```javascript
    this.createOverlay(this.targetEl);
```

with:

```javascript
    this.createOverlay(this.targetEl, tour.overlay_enabled);
```

- [ ] **Step 11: Write controller test for overlay_enabled**

Add to `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb` inside `describe "POST #create"`, after the existing test:

```ruby
    it "creates a tour with overlay_enabled false" do
      post :create, params: { tour: { name: "No Overlay", overlay_enabled: "0" } }
      expect(OnboardOnRails::Tour.last.overlay_enabled).to eq(false)
    end
```

- [ ] **Step 12: Run all tests**

```bash
bundle exec rspec spec/models/onboard_on_rails/tour_spec.rb spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb
```

Expected: All PASS

- [ ] **Step 13: Commit**

```bash
git add db/migrate/20260414000001_add_overlay_enabled_to_onboard_on_rails_tours.rb \
  app/controllers/onboard_on_rails/admin/tours_controller.rb \
  app/views/onboard_on_rails/admin/tours/_form.html.erb \
  app/controllers/onboard_on_rails/api/tours_controller.rb \
  app/assets/javascripts/onboard_on_rails/client.js \
  config/locales/en.yml config/locales/ru.yml \
  spec/models/onboard_on_rails/tour_spec.rb \
  spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb
git commit -m "feat: add overlay_enabled toggle for tours"
```

---

### Task 3: Add min_width to step style_overrides

**Files:**
- Modify: `app/views/onboard_on_rails/admin/steps/_form.html.erb:133`
- Modify: `app/assets/javascripts/onboard_on_rails/client.js` (ThemeEngine)
- Modify: `app/assets/stylesheets/onboard_on_rails/client.css:18-25`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/ru.yml`

- [ ] **Step 1: Add min-width CSS variable to client.css**

In `app/assets/stylesheets/onboard_on_rails/client.css`, add a new CSS variable in `.oor-tour-step` (after `--oor-step-max-width: 320px;` on line 25):

```css
  --oor-step-min-width: auto;
```

And add the `min-width` property (after `max-width: var(--oor-step-max-width);` on line 34):

```css
  min-width: var(--oor-step-min-width);
```

- [ ] **Step 2: Add min_width handling in ThemeEngine**

In `app/assets/javascripts/onboard_on_rails/client.js`, add after the `max_width` line (after line 94):

```javascript
    if (overrides.min_width) container.style.setProperty("--oor-step-min-width", overrides.min_width + "px");
```

- [ ] **Step 3: Add min_width input to step form**

In `app/views/onboard_on_rails/admin/steps/_form.html.erb`, add after the border_radius select (after line 133, before the button_color group):

```erb
  <div class="oor-form-group">
    <label><%= t("onboard_on_rails.admin.steps.form.styles.min_width") %></label>
    <input type="number" name="step[style_overrides][min_width]" value="<%= step.style_overrides&.dig('min_width') %>" placeholder="auto" min="0" step="10">
    <div class="oor-form-hint"><%= t("onboard_on_rails.admin.steps.form.hints.min_width") %></div>
  </div>
```

- [ ] **Step 4: Add locale entries**

In `config/locales/en.yml`, add under `steps.form.styles:` (after `button_color:` line 121):

```yaml
            min_width: "Min Width (px)"
```

And under `steps.form.hints:` (after `button_color:` line 113):

```yaml
            min_width: "Minimum width in pixels. Leave empty for default."
```

In `config/locales/ru.yml`, add under `steps.form.styles:` (after `button_color:` line 184):

```yaml
            min_width: "Мин. ширина (px)"
```

And under `steps.form.hints:` (after `button_color:` line 176):

```yaml
            min_width: "Минимальная ширина в пикселях. Оставьте пустым для значения по умолчанию."
```

- [ ] **Step 5: Verify manually**

Start the dev server, create a step with `min_width: 500`, confirm the tooltip/modal renders at least 500px wide.

- [ ] **Step 6: Commit**

```bash
git add app/assets/stylesheets/onboard_on_rails/client.css \
  app/assets/javascripts/onboard_on_rails/client.js \
  app/views/onboard_on_rails/admin/steps/_form.html.erb \
  config/locales/en.yml config/locales/ru.yml
git commit -m "feat: add min_width to step style overrides"
```

---

### Task 4: Configurable default font

**Files:**
- Modify: `lib/onboard_on_rails/configuration.rb:3-4, 12-18`
- Modify: `app/helpers/onboard_on_rails/meta_tags_helper.rb:12-16`
- Modify: `app/assets/javascripts/onboard_on_rails/client.js:421-428` (TourManager.init)
- Modify: `app/views/onboard_on_rails/admin/steps/_form.html.erb:109`

- [ ] **Step 1: Add default_font to Configuration**

In `lib/onboard_on_rails/configuration.rb`, add `default_font` to the attr_accessor on line 3:

```ruby
    attr_accessor :user_class, :admin_auth, :user_attributes, :current_user_method, :user_locale, :default_font
```

And add the default in `initialize` (after `@accent_color = "#2d3436"` on line 17):

```ruby
      @default_font = nil
```

- [ ] **Step 2: Add meta tag for default_font**

In `app/helpers/onboard_on_rails/meta_tags_helper.rb`, add after the locale meta tag (after line 16, before the method end):

```ruby
      if OnboardOnRails.configuration.default_font.present?
        tags += tag.meta(name: "onboard-on-rails-default-font", content: OnboardOnRails.configuration.default_font)
      end

      tags
```

Also, change the return value. Replace the concatenation (lines 12-16) with a variable:

```ruby
      tags = tag.meta(name: "onboard-on-rails-user-id", content: user.id) +
        tag.meta(name: "onboard-on-rails-mount-path", content: mount_path) +
        tag.meta(name: "onboard-on-rails-accent-color", content: OnboardOnRails.configuration.accent_color) +
        tag.meta(name: "csrf-token", content: form_authenticity_token) +
        tag.meta(name: "onboard-on-rails-locale", content: locale)

      if OnboardOnRails.configuration.default_font.present?
        tags += tag.meta(name: "onboard-on-rails-default-font", content: OnboardOnRails.configuration.default_font)
      end

      tags
```

- [ ] **Step 3: Read default_font meta tag in TourManager.init**

In `app/assets/javascripts/onboard_on_rails/client.js`, in `TourManager.init()`, add after the accent color block (after line 426):

```javascript
    var fontMeta = document.querySelector('meta[name="onboard-on-rails-default-font"]');
    if (fontMeta && fontMeta.content) {
      document.documentElement.style.setProperty("--oor-step-font", fontMeta.content);
    }
```

- [ ] **Step 4: Add Rubik to font dropdown in step form**

In `app/views/onboard_on_rails/admin/steps/_form.html.erb`, change the font list on line 109:

```erb
      <% %w[Arial Helvetica Georgia Times\ New\ Roman Courier\ New Verdana Rubik].each do |font| %>
```

- [ ] **Step 5: Run full test suite**

```bash
bundle exec rspec
```

Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add lib/onboard_on_rails/configuration.rb \
  app/helpers/onboard_on_rails/meta_tags_helper.rb \
  app/assets/javascripts/onboard_on_rails/client.js \
  app/views/onboard_on_rails/admin/steps/_form.html.erb
git commit -m "feat: add configurable default font via engine config"
```

---

### Task 5: Final verification

**Files:** None (testing only)

- [ ] **Step 1: Run full test suite**

```bash
bundle exec rspec
```

Expected: All tests PASS

- [ ] **Step 2: Manual smoke test**

Start dev server and verify:
1. Single-step tour — no navigation dots
2. Multi-step tour — dots visible
3. Tour with overlay disabled — no dark background, clicking outside still works
4. Step with min_width: 500 — tooltip is at least 500px wide
5. Configure `default_font = "Rubik"` in initializer — all tours use Rubik
6. Step-level font_family override still works on top of default_font

```bash
cd spec/dummy && RAILS_ENV=development bin/rails server
```
