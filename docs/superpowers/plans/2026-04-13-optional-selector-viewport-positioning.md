# Optional Selector & Viewport Positioning — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make CSS selector optional for tour steps; when empty, position all themes relative to the viewport based on the step's placement setting.

**Architecture:** Remove the selector validation from the Step model, add a `positionViewport` method to PositioningEngine for fixed viewport positioning, update TourRenderer and TourManager to use it when no target element exists, and add a hint in the admin form.

**Tech Stack:** Ruby on Rails engine, vanilla JS (Sprockets), RSpec, FactoryBot

---

### Task 1: Make selector optional in Step model

**Files:**
- Modify: `app/models/onboard_on_rails/step.rb:12` — remove selector validation
- Modify: `config/locales/ru.yml:23-24` — remove selector blank error message
- Modify: `spec/models/onboard_on_rails/step_spec.rb:10-13` — update test
- Modify: `spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb:22-28` — add test

- [ ] **Step 1: Update the spec — change "requires a selector" to "is valid without a selector"**

In `spec/models/onboard_on_rails/step_spec.rb`, replace the existing test:

```ruby
    it "requires a selector" do
      step = build(:step, selector: nil)
      expect(step).not_to be_valid
    end
```

with:

```ruby
    it "is valid without a selector" do
      step = build(:step, selector: nil)
      expect(step).to be_valid
    end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bundle exec rspec spec/models/onboard_on_rails/step_spec.rb`
Expected: FAIL — `expected #<OnboardOnRails::Step ...> to be valid`

- [ ] **Step 3: Remove the validation from the model**

In `app/models/onboard_on_rails/step.rb`, remove line 12:

```ruby
    validates :selector, presence: true
```

So the validates block becomes:

```ruby
    validates :title, presence: true
    validates :placement, inclusion: { in: PLACEMENTS }
    validates :action_type, inclusion: { in: ACTION_TYPES }
```

- [ ] **Step 4: Remove the selector blank error message from ru.yml**

In `config/locales/ru.yml`, remove lines 23-24:

```yaml
            selector:
              blank: "не может быть пустым"
```

- [ ] **Step 5: Add a controller test for creating a step without selector**

In `spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb`, add after the existing `POST #create` test (after line 28):

```ruby
    it "creates a step without a selector" do
      post :create, params: {
        tour_id: tour.id,
        step: { title: "Hello", selector: "", placement: "center" }
      }
      expect(tour.steps.count).to eq(1)
      expect(tour.steps.first.selector).to eq("")
    end
```

- [ ] **Step 6: Run all tests to verify everything passes**

Run: `bundle exec rspec spec/models/onboard_on_rails/step_spec.rb spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb`
Expected: all green

- [ ] **Step 7: Commit**

```bash
git add app/models/onboard_on_rails/step.rb config/locales/ru.yml spec/models/onboard_on_rails/step_spec.rb spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb
git commit -m "feat: make CSS selector optional for tour steps"
```

---

### Task 2: Add `positionViewport` method to PositioningEngine

**Files:**
- Modify: `app/assets/javascripts/onboard_on_rails/client.js:82-148` — add method to PositioningEngine

- [ ] **Step 1: Add `positionViewport` method**

In `app/assets/javascripts/onboard_on_rails/client.js`, add the following method to the `PositioningEngine` object, right after the `scrollIntoView` method (after line 147, before the closing `};` of PositioningEngine):

```js
  positionViewport(tooltip, placement) {
    tooltip.style.position = "fixed";
    tooltip.style.zIndex = "10001";
    switch (placement) {
      case "top":
        tooltip.style.top = this.MARGIN + "px";
        tooltip.style.left = "50%";
        tooltip.style.transform = "translateX(-50%)";
        break;
      case "bottom":
        tooltip.style.bottom = this.MARGIN + "px";
        tooltip.style.left = "50%";
        tooltip.style.transform = "translateX(-50%)";
        break;
      case "left":
        tooltip.style.top = "50%";
        tooltip.style.left = this.MARGIN + "px";
        tooltip.style.transform = "translateY(-50%)";
        break;
      case "right":
        tooltip.style.top = "50%";
        tooltip.style.right = this.MARGIN + "px";
        tooltip.style.transform = "translateY(-50%)";
        break;
      case "center":
      default:
        tooltip.style.top = "50%";
        tooltip.style.left = "50%";
        tooltip.style.transform = "translate(-50%, -50%)";
        break;
    }
  }
```

The method should be placed so the PositioningEngine object looks like:

```js
OnboardOnRails.PositioningEngine = {
  MARGIN: 12,
  position(tooltip, targetEl, placement) { ... },
  resolvePlacement(preferred, targetRect, tooltipRect) { ... },
  getClipPath(targetEl) { ... },
  scrollIntoView(targetEl) { ... },
  positionViewport(tooltip, placement) { ... }   // <-- new method here
};
```

- [ ] **Step 2: Commit**

```bash
git add app/assets/javascripts/onboard_on_rails/client.js
git commit -m "feat: add positionViewport method to PositioningEngine"
```

---

### Task 3: Update TourRenderer and TourManager to handle missing selector

**Files:**
- Modify: `app/assets/javascripts/onboard_on_rails/client.js` — TourRenderer.show, TourRenderer.createTooltip, TourManager.showStep

- [ ] **Step 1: Update `TourRenderer.show` — remove early return**

In `app/assets/javascripts/onboard_on_rails/client.js`, in the `show` method of `TourRenderer`, find these lines (around line 229-230):

```js
    this.targetEl = step.selector ? document.querySelector(step.selector) : null;
    if (!this.targetEl && step.placement !== "center") return;
```

Replace with:

```js
    this.targetEl = step.selector ? document.querySelector(step.selector) : null;
```

Just remove the second line entirely.

- [ ] **Step 2: Update `TourRenderer.createTooltip` — use positionViewport**

In the same file, in `createTooltip`, find the positioning block (around lines 302-310):

```js
    if (targetEl) {
      OnboardOnRails.PositioningEngine.position(this.tooltip, targetEl, step.placement);
    } else {
      this.tooltip.style.position = "fixed";
      this.tooltip.style.top = "50%";
      this.tooltip.style.left = "50%";
      this.tooltip.style.transform = "translate(-50%, -50%)";
      this.tooltip.style.zIndex = "10001";
    }
```

Replace with:

```js
    if (targetEl) {
      OnboardOnRails.PositioningEngine.position(this.tooltip, targetEl, step.placement);
    } else {
      OnboardOnRails.PositioningEngine.positionViewport(this.tooltip, step.placement);
    }
```

- [ ] **Step 3: Update `TourManager.showStep` — handle missing selector**

In the same file, in `showStep`, find the block that decides how to show the step (around lines 386-389):

```js
      const targetEl = (step.placement === "center" && !step.selector) ? true : document.querySelector(step.selector);
      if (targetEl) showFn();
      else OnboardOnRails.DOMObserver.waitForSelector(step.selector, showFn);
```

Replace with:

```js
      if (!step.selector) {
        showFn();
      } else {
        const targetEl = document.querySelector(step.selector);
        if (targetEl) showFn();
        else OnboardOnRails.DOMObserver.waitForSelector(step.selector, showFn);
      }
```

- [ ] **Step 4: Commit**

```bash
git add app/assets/javascripts/onboard_on_rails/client.js
git commit -m "feat: support viewport positioning when step has no selector"
```

---

### Task 4: Add hint to admin form and locales

**Files:**
- Modify: `app/views/onboard_on_rails/admin/steps/_form.html.erb:41` — add hint
- Modify: `config/locales/en.yml:105` — add selector_empty key
- Modify: `config/locales/ru.yml:170` — add selector_empty key

- [ ] **Step 1: Add hint to the step form**

In `app/views/onboard_on_rails/admin/steps/_form.html.erb`, find line 41:

```erb
    <div class="oor-form-hint"><%= t("onboard_on_rails.admin.steps.form.hints.selector") %></div>
```

Add the following line right after it:

```erb
    <div class="oor-form-hint"><%= t("onboard_on_rails.admin.steps.form.hints.selector_empty") %></div>
```

- [ ] **Step 2: Add English locale key**

In `config/locales/en.yml`, find the `selector` hint (line 105):

```yaml
            selector: "CSS selector for the target element (e.g., #main-header, .btn-primary)"
```

Add after it:

```yaml
            selector_empty: "If left empty, the step will be positioned relative to the viewport"
```

- [ ] **Step 3: Add Russian locale key**

In `config/locales/ru.yml`, find the `selector` hint (line 170):

```yaml
            selector: "CSS селектор целевого элемента (например, #main-header, .btn-primary)"
```

Add after it:

```yaml
            selector_empty: "Если не указан, шаг будет позиционироваться относительно видимой части экрана"
```

- [ ] **Step 4: Run full test suite to verify nothing is broken**

Run: `bundle exec rspec`
Expected: all green

- [ ] **Step 5: Commit**

```bash
git add app/views/onboard_on_rails/admin/steps/_form.html.erb config/locales/en.yml config/locales/ru.yml
git commit -m "feat: add viewport positioning hint to step form"
```
