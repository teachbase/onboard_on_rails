# Complete on Target Click — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow steps to optionally complete when the user clicks the target element, using `sendBeacon` to guarantee delivery before page navigation.

**Architecture:** Add a boolean `complete_on_target_click` column to steps. Client attaches a click listener on the target element when the flag is true; on click, fires `navigator.sendBeacon()` with the same completion payload the existing flow uses. Admin form gets a checkbox.

**Tech Stack:** Rails migration, ERB form, vanilla JS, RSpec

**Spec:** `docs/superpowers/specs/2026-04-04-complete-on-target-click-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Create | `db/migrate/XXXXXX_add_complete_on_target_click_to_steps.rb` | Boolean column |
| Modify | `app/controllers/onboard_on_rails/admin/steps_controller.rb:48-52` | Strong params |
| Modify | `app/controllers/onboard_on_rails/api/tours_controller.rb:36-51` | API serialization |
| Modify | `app/views/onboard_on_rails/admin/steps/_form.html.erb:29-42` | Checkbox in form |
| Modify | `config/locales/en.yml:82-97` | English label + hint |
| Modify | `config/locales/ru.yml:141-162` | Russian label + hint |
| Modify | `app/assets/javascripts/onboard_on_rails/client.js:321-435` | Target click listener + sendBeacon |
| Modify | `spec/models/onboard_on_rails/step_spec.rb` | Default value test |
| Modify | `spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb` | Strong params test |
| Modify | `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb` | API serialization test |

---

### Task 1: Migration — add `complete_on_target_click` column

**Files:**
- Create: `db/migrate/XXXXXX_add_complete_on_target_click_to_steps.rb`

- [ ] **Step 1: Generate migration**

Run: `cd spec/dummy && bin/rails generate migration AddCompleteOnTargetClickToOnboardOnRailsSteps complete_on_target_click:boolean`

- [ ] **Step 2: Edit migration to add default and null constraint**

Replace the generated migration body with:

```ruby
class AddCompleteOnTargetClickToOnboardOnRailsSteps < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_steps, :complete_on_target_click, :boolean, default: false, null: false
  end
end
```

- [ ] **Step 3: Run migration**

Run: `cd spec/dummy && bin/rails db:migrate`

Expected: migration succeeds, `schema.rb` updated with `complete_on_target_click` column.

- [ ] **Step 4: Commit**

```bash
git add db/migrate/*_add_complete_on_target_click_to_onboard_on_rails_steps.rb spec/dummy/db/schema.rb
git commit -m "feat: add complete_on_target_click column to steps"
```

---

### Task 2: Model test — verify default value

**Files:**
- Modify: `spec/models/onboard_on_rails/step_spec.rb`

- [ ] **Step 1: Write failing test**

Add to `spec/models/onboard_on_rails/step_spec.rb` after the `"is valid with all required attributes"` test (after line 28), inside the `"validations"` describe block:

```ruby
    it "defaults complete_on_target_click to false" do
      step = create(:step)
      expect(step.complete_on_target_click).to eq(false)
    end
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd spec/dummy && bundle exec rspec ../../spec/models/onboard_on_rails/step_spec.rb`

Expected: PASS — the column already exists from Task 1 with `default: false`.

- [ ] **Step 3: Commit**

```bash
git add spec/models/onboard_on_rails/step_spec.rb
git commit -m "test: verify complete_on_target_click defaults to false"
```

---

### Task 3: Admin controller — strong params + test

**Files:**
- Modify: `app/controllers/onboard_on_rails/admin/steps_controller.rb:47-52`
- Modify: `spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb`

- [ ] **Step 1: Write failing test**

Add to `spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb` after the `"PATCH #update"` describe block (after line 45):

```ruby
  describe "PATCH #update complete_on_target_click" do
    it "saves complete_on_target_click flag" do
      step = create(:step, tour: tour, complete_on_target_click: false)
      patch :update, params: {
        tour_id: tour.id, id: step.id,
        step: { complete_on_target_click: "1" }
      }
      expect(step.reload.complete_on_target_click).to eq(true)
    end
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd spec/dummy && bundle exec rspec ../../spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb`

Expected: FAIL — `complete_on_target_click` is not in `step_params` permit list, so it gets filtered out and stays `false`.

- [ ] **Step 3: Add to strong params**

In `app/controllers/onboard_on_rails/admin/steps_controller.rb`, change line 48-52 from:

```ruby
      def step_params
        params.require(:step).permit(
          :title, :body, :selector, :placement, :position,
          :url_pattern, :action_type, :action_value, :wait_for_selector,
          style_overrides: {}
        )
      end
```

to:

```ruby
      def step_params
        params.require(:step).permit(
          :title, :body, :selector, :placement, :position,
          :url_pattern, :action_type, :action_value, :wait_for_selector,
          :complete_on_target_click,
          style_overrides: {}
        )
      end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd spec/dummy && bundle exec rspec ../../spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb`

Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add app/controllers/onboard_on_rails/admin/steps_controller.rb spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb
git commit -m "feat: permit complete_on_target_click in step strong params"
```

---

### Task 4: API serialization — expose field + test

**Files:**
- Modify: `app/controllers/onboard_on_rails/api/tours_controller.rb:36-51`
- Modify: `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`

- [ ] **Step 1: Write failing test**

Add to `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb` after the `"returns matched_url per step from completion"` test (after line 79), inside the `"GET #index"` describe block:

```ruby
    it "returns complete_on_target_click for each step" do
      tour = create(:tour, url_pattern: ["/dashboard/*"])
      create(:step, tour: tour, position: 1, complete_on_target_click: true)
      create(:step, tour: tour, position: 2, complete_on_target_click: false)

      get :index, params: { url: "/dashboard/home" }, format: :json

      json = JSON.parse(response.body)
      expect(json["tour"]["steps"][0]["complete_on_target_click"]).to eq(true)
      expect(json["tour"]["steps"][1]["complete_on_target_click"]).to eq(false)
    end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd spec/dummy && bundle exec rspec ../../spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`

Expected: FAIL — `complete_on_target_click` key not present in JSON response.

- [ ] **Step 3: Add to serialize_step**

In `app/controllers/onboard_on_rails/api/tours_controller.rb`, change `serialize_step` method (lines 36-51) from:

```ruby
      def serialize_step(step, matched_urls)
        {
          id: step.id,
          position: step.position,
          title: step.title,
          body: step.body,
          selector: step.selector,
          placement: step.placement,
          url_pattern: step.url_pattern,
          matched_url: matched_urls[step.id.to_s],
          style_overrides: step.style_overrides,
          action_type: step.action_type,
          action_value: step.action_value,
          wait_for_selector: step.wait_for_selector
        }
      end
```

to:

```ruby
      def serialize_step(step, matched_urls)
        {
          id: step.id,
          position: step.position,
          title: step.title,
          body: step.body,
          selector: step.selector,
          placement: step.placement,
          url_pattern: step.url_pattern,
          matched_url: matched_urls[step.id.to_s],
          style_overrides: step.style_overrides,
          action_type: step.action_type,
          action_value: step.action_value,
          wait_for_selector: step.wait_for_selector,
          complete_on_target_click: step.complete_on_target_click
        }
      end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd spec/dummy && bundle exec rspec ../../spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`

Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add app/controllers/onboard_on_rails/api/tours_controller.rb spec/controllers/onboard_on_rails/api/tours_controller_spec.rb
git commit -m "feat: expose complete_on_target_click in API response"
```

---

### Task 5: Locales — add labels and hint

**Files:**
- Modify: `config/locales/en.yml:82-97`
- Modify: `config/locales/ru.yml:141-162`

- [ ] **Step 1: Add English locale**

In `config/locales/en.yml`, add `complete_on_target_click` label inside `steps.form.labels` (after line 91, after `wait_for_selector`):

```yaml
            complete_on_target_click: "Complete on target click"
```

And add a hint inside `steps.form.hints` (after line 97, after `url_pattern` hint):

```yaml
            complete_on_target_click: "When enabled, clicking the target element completes this step automatically."
```

- [ ] **Step 2: Add Russian locale**

In `config/locales/ru.yml`, add label inside `steps.form.labels` (after line 156, after `wait_for_selector`):

```yaml
            complete_on_target_click: "Засчитывать клик по элементу"
```

And add a hint inside `steps.form.hints` (after line 162, after `url_pattern` hint):

```yaml
            complete_on_target_click: "Клик по целевому элементу автоматически засчитывает выполнение шага."
```

- [ ] **Step 3: Commit**

```bash
git add config/locales/en.yml config/locales/ru.yml
git commit -m "feat: add complete_on_target_click locale strings"
```

---

### Task 6: Admin form — add checkbox

**Files:**
- Modify: `app/views/onboard_on_rails/admin/steps/_form.html.erb:29-42`

- [ ] **Step 1: Add checkbox after the selector field**

In `app/views/onboard_on_rails/admin/steps/_form.html.erb`, add a new form group after the selector group's closing `</div>` (after line 42, before the placement group that starts at line 44):

```erb
  <div class="oor-form-group">
    <label>
      <%= f.check_box :complete_on_target_click %>
      <%= t("onboard_on_rails.admin.steps.form.labels.complete_on_target_click") %>
    </label>
    <div class="oor-form-hint"><%= t("onboard_on_rails.admin.steps.form.hints.complete_on_target_click") %></div>
  </div>
```

- [ ] **Step 2: Verify in browser**

Run: `cd spec/dummy && RAILS_ENV=development bin/rails server`

Visit `http://localhost:3000/onboard/admin`, create or edit a tour, add a step. Verify:
- Checkbox appears after the CSS Selector field
- Label reads "Засчитывать клик по элементу" (or English equivalent)
- Hint text is shown below
- Saving with checkbox checked persists the value
- Saving with checkbox unchecked persists false

- [ ] **Step 3: Commit**

```bash
git add app/views/onboard_on_rails/admin/steps/_form.html.erb
git commit -m "feat: add complete_on_target_click checkbox to step form"
```

---

### Task 7: Client JS — sendBeacon helper + target click listener

**Files:**
- Modify: `app/assets/javascripts/onboard_on_rails/client.js`

- [ ] **Step 1: Add `sendCompletionBeacon` method to ApiClient**

In `app/assets/javascripts/onboard_on_rails/client.js`, add a new method to `ApiClient` after the `trackEvent` method (after line 52, before the closing `};` on line 53):

```javascript
  sendCompletionBeacon(tourId, stepId, status, sessionId, matchedUrl, matchedStepId) {
    const mountPath = this.getMountPath();
    const body = { tour_id: tourId, step_id: stepId, status, session_id: sessionId };
    if (matchedUrl && matchedStepId) {
      body.matched_url = matchedUrl;
      body.matched_step_id = matchedStepId;
    }
    const blob = new Blob([JSON.stringify(body)], { type: "application/json" });
    navigator.sendBeacon(`${mountPath}/api/completions`, blob);
  }
```

- [ ] **Step 2: Add target click listener state to TourManager**

In `app/assets/javascripts/onboard_on_rails/client.js`, change the TourManager declaration (line 322) from:

```javascript
OnboardOnRails.TourManager = {
  currentTour: null, currentStepIndex: 0, sessionId: null,
```

to:

```javascript
OnboardOnRails.TourManager = {
  currentTour: null, currentStepIndex: 0, sessionId: null,
  _targetClickEl: null, _targetClickHandler: null,
```

- [ ] **Step 3: Add `_clearTargetClickListener` and `_attachTargetClickListener` methods**

In `app/assets/javascripts/onboard_on_rails/client.js`, add two new methods after `getOrCreateSessionId` (after line 433, before the closing `};` on line 434):

```javascript
  _clearTargetClickListener() {
    if (this._targetClickEl && this._targetClickHandler) {
      this._targetClickEl.removeEventListener("click", this._targetClickHandler);
    }
    this._targetClickEl = null;
    this._targetClickHandler = null;
  },

  _attachTargetClickListener(step) {
    if (!step.complete_on_target_click) return;

    const targetEl = document.querySelector(step.selector);
    if (!targetEl) return;

    const tour = this.currentTour;
    const currentStep = step;
    const stepIndex = this.currentStepIndex;
    const isLast = stepIndex === tour.steps.length - 1;
    const nextStep = tour.steps[stepIndex + 1];

    this._targetClickHandler = () => {
      this._clearTargetClickListener();

      if (isLast) {
        OnboardOnRails.ApiClient.sendCompletionBeacon(
          tour.id, currentStep.id, "completed", this.sessionId
        );
        this.currentTour = null;
      } else if (nextStep) {
        OnboardOnRails.ApiClient.sendCompletionBeacon(
          tour.id, nextStep.id, "in_progress", this.sessionId,
          window.location.pathname, currentStep.id
        );
      }
    };

    this._targetClickEl = targetEl;
    targetEl.addEventListener("click", this._targetClickHandler);
  }
```

- [ ] **Step 4: Call `_attachTargetClickListener` from `showStep`**

In `app/assets/javascripts/onboard_on_rails/client.js`, modify the `showStep` method. Change the `showFn` definition (lines 354-358) from:

```javascript
    const showFn = () => {
      OnboardOnRails.TourRenderer.show(this.currentTour, this.currentStepIndex, {
        next: () => this.next(), prev: () => this.prev(),
        dismiss: () => this.dismiss(), complete: () => this.complete()
      });
    };
```

to:

```javascript
    const showFn = () => {
      OnboardOnRails.TourRenderer.show(this.currentTour, this.currentStepIndex, {
        next: () => this.next(), prev: () => this.prev(),
        dismiss: () => this.dismiss(), complete: () => this.complete()
      });
      this._attachTargetClickListener(step);
    };
```

- [ ] **Step 5: Clear listener on step change and cleanup**

In `app/assets/javascripts/onboard_on_rails/client.js`, add `this._clearTargetClickListener();` as the first line in the `showStep` method (after line 342, `if (!this.currentTour) return;`):

```javascript
    this._clearTargetClickListener();
```

Also add `this._clearTargetClickListener();` at the beginning of both `dismiss()` and `complete()` methods:

In `dismiss()` (currently line 417), add as first line:

```javascript
    this._clearTargetClickListener();
```

In `complete()` (currently line 424), add as first line:

```javascript
    this._clearTargetClickListener();
```

- [ ] **Step 6: Run full test suite**

Run: `cd spec/dummy && bundle exec rspec`

Expected: ALL PASS — JS changes don't affect server-side tests.

- [ ] **Step 7: Commit**

```bash
git add app/assets/javascripts/onboard_on_rails/client.js
git commit -m "feat: add target click listener with sendBeacon for step completion"
```

---

### Task 8: Manual end-to-end verification

- [ ] **Step 1: Start dev server**

Run: `cd spec/dummy && RAILS_ENV=development bin/rails server`

- [ ] **Step 2: Create a test tour**

Visit `http://localhost:3000/onboard/admin`.
1. Create a new tour with `url_pattern: /onboard/admin/*`, status: active
2. Add step 1: title "Click the button below", selector for any clickable element on the page, `complete_on_target_click` checked
3. Add step 2: title "You did it!", any selector

- [ ] **Step 3: Verify target click completes the step**

Open the page matching the tour URL. Verify:
- Step 1 tooltip appears
- Clicking the target element completes step 1 (check via admin stats or DB)
- If step 1's target triggers navigation, the completion is recorded (check DB: `OnboardOnRails::Completion` status should be `in_progress` with `step_id` = step 2's ID)

- [ ] **Step 4: Verify "Next" button still works**

Reset the completion (delete from DB or use a different user). Verify clicking "Next" in the tooltip still advances the step normally.

- [ ] **Step 5: Verify unchecked flag has no effect**

Edit step 1, uncheck `complete_on_target_click`. Verify clicking the target element does NOT advance the step — only "Next"/"Done" buttons work.
