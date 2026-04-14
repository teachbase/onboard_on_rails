# Device Type Targeting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow admins to target tours by device type (desktop/mobile/all), with client-side detection by screen width.

**Architecture:** New `device_type` string column on tours table, client sends device type in API request, `TourMatcher` filters by it. Simple AND with all existing targeting conditions.

**Tech Stack:** Rails migration, Ruby model/service/controller changes, vanilla JS, RSpec.

---

## File Map

- **Create:** `db/migrate/XXXXXX_add_device_type_to_onboard_on_rails_tours.rb` — migration
- **Modify:** `app/models/onboard_on_rails/tour.rb` — constant + validation
- **Modify:** `spec/factories/tours.rb` — factory traits
- **Modify:** `spec/models/onboard_on_rails/tour_spec.rb` — validation tests
- **Modify:** `app/services/onboard_on_rails/tour_matcher.rb` — device filtering
- **Modify:** `spec/services/onboard_on_rails/tour_matcher_spec.rb` — matcher tests
- **Modify:** `app/controllers/onboard_on_rails/api/tours_controller.rb` — pass param
- **Modify:** `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb` — controller tests
- **Modify:** `app/controllers/onboard_on_rails/admin/tours_controller.rb` — permit param
- **Modify:** `app/views/onboard_on_rails/admin/tours/_form.html.erb` — select field
- **Modify:** `config/locales/en.yml` — English translations
- **Modify:** `config/locales/ru.yml` — Russian translations
- **Modify:** `app/assets/javascripts/onboard_on_rails/client.js` — send device_type param

---

### Task 1: Migration + Model

**Files:**
- Create: `db/migrate/XXXXXX_add_device_type_to_onboard_on_rails_tours.rb`
- Modify: `app/models/onboard_on_rails/tour.rb`
- Modify: `spec/factories/tours.rb`
- Test: `spec/models/onboard_on_rails/tour_spec.rb`

- [ ] **Step 1: Write the failing test for device_type validation**

Add to `spec/models/onboard_on_rails/tour_spec.rb` inside the `describe "validations"` block:

```ruby
it "validates device_type inclusion" do
  tour = build(:tour, device_type: "invalid")
  expect(tour).not_to be_valid
end

it "defaults device_type to all" do
  tour = build(:tour)
  expect(tour.device_type).to eq("all")
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/models/onboard_on_rails/tour_spec.rb`
Expected: FAIL — `device_type` column does not exist yet.

- [ ] **Step 3: Create the migration**

Run:
```bash
cd spec/dummy && bin/rails generate migration AddDeviceTypeToOnboardOnRailsTours device_type:string --no-test-framework
```

Then edit the generated migration file to:

```ruby
class AddDeviceTypeToOnboardOnRailsTours < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_tours, :device_type, :string, default: "all", null: false
  end
end
```

Then run:
```bash
cd spec/dummy && bin/rails db:migrate
```

- [ ] **Step 4: Add constant and validation to Tour model**

In `app/models/onboard_on_rails/tour.rb`, add after the `THEMES` constant:

```ruby
DEVICE_TYPES = %w[all desktop mobile].freeze
```

And add after the `validates :theme` line:

```ruby
validates :device_type, inclusion: { in: DEVICE_TYPES }
```

- [ ] **Step 5: Add factory traits**

In `spec/factories/tours.rb`, add inside the factory block:

```ruby
trait :desktop_only do
  device_type { "desktop" }
end

trait :mobile_only do
  device_type { "mobile" }
end
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bundle exec rspec spec/models/onboard_on_rails/tour_spec.rb`
Expected: ALL PASS

- [ ] **Step 7: Commit**

```bash
git add db/migrate/*_add_device_type_to_onboard_on_rails_tours.rb app/models/onboard_on_rails/tour.rb spec/models/onboard_on_rails/tour_spec.rb spec/factories/tours.rb
git commit -m "feat: add device_type column and validation to Tour model"
```

---

### Task 2: TourMatcher device filtering

**Files:**
- Modify: `app/services/onboard_on_rails/tour_matcher.rb`
- Test: `spec/services/onboard_on_rails/tour_matcher_spec.rb`

- [ ] **Step 1: Write the failing tests**

Add to `spec/services/onboard_on_rails/tour_matcher_spec.rb` inside the `describe "#match"` block:

```ruby
context "device type filtering" do
  it "returns tour with device_type 'all' for any device" do
    tour = create(:tour, url_pattern: ["/dashboard/*"], device_type: "all")
    create(:step, tour: tour)

    result = described_class.new(user: user, url: "/dashboard/home", device_type: "mobile").match
    expect(result).to eq(tour)
  end

  it "returns tour when device_type matches" do
    tour = create(:tour, :mobile_only, url_pattern: ["/dashboard/*"])
    create(:step, tour: tour)

    result = described_class.new(user: user, url: "/dashboard/home", device_type: "mobile").match
    expect(result).to eq(tour)
  end

  it "excludes tour when device_type does not match" do
    tour = create(:tour, :desktop_only, url_pattern: ["/dashboard/*"])
    create(:step, tour: tour)

    result = described_class.new(user: user, url: "/dashboard/home", device_type: "mobile").match
    expect(result).to be_nil
  end

  it "returns any tour when device_type param is blank" do
    tour = create(:tour, :mobile_only, url_pattern: ["/dashboard/*"])
    create(:step, tour: tour)

    result = described_class.new(user: user, url: "/dashboard/home").match
    expect(result).to eq(tour)
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/services/onboard_on_rails/tour_matcher_spec.rb`
Expected: FAIL — `ArgumentError: unknown keyword: device_type`

- [ ] **Step 3: Implement device filtering in TourMatcher**

In `app/services/onboard_on_rails/tour_matcher.rb`:

Update `initialize` to accept the new keyword argument:

```ruby
def initialize(user:, url:, session_id: nil, device_type: nil)
  @user = user
  @url = url
  @session_id = session_id
  @device_type = device_type
  @user_attributes = OnboardOnRails.configuration.user_attributes.call(user)
  @current_step_index = 0
end
```

Add the device filter to the `match` method's candidate chain, after the segment filter line `candidates = candidates.select { |t| t.matches_segment?(@user_attributes) }`:

```ruby
candidates = candidates.select { |t| matches_device?(t) }
```

Add the private method:

```ruby
def matches_device?(tour)
  return true if tour.device_type == "all"
  return true if @device_type.blank?
  tour.device_type == @device_type
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/services/onboard_on_rails/tour_matcher_spec.rb`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add app/services/onboard_on_rails/tour_matcher.rb spec/services/onboard_on_rails/tour_matcher_spec.rb
git commit -m "feat: add device type filtering to TourMatcher"
```

---

### Task 3: API controller — pass device_type param

**Files:**
- Modify: `app/controllers/onboard_on_rails/api/tours_controller.rb`
- Test: `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`

- [ ] **Step 1: Write the failing tests**

Add to `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb` inside the `describe "GET #index"` block:

```ruby
it "filters tours by device_type param" do
  tour = create(:tour, url_pattern: ["/dashboard/*"], device_type: "desktop")
  create(:step, tour: tour)

  get :index, params: { url: "/dashboard/home", device_type: "mobile" }, format: :json

  json = JSON.parse(response.body)
  expect(json["tour"]).to be_nil
end

it "returns desktop tour when device_type is desktop" do
  tour = create(:tour, url_pattern: ["/dashboard/*"], device_type: "desktop")
  create(:step, tour: tour)

  get :index, params: { url: "/dashboard/home", device_type: "desktop" }, format: :json

  json = JSON.parse(response.body)
  expect(json["tour"]["id"]).to eq(tour.id)
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec rspec spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`
Expected: First test FAILS — tour is returned even though device type doesn't match (param not being passed through yet).

- [ ] **Step 3: Pass device_type param to TourMatcher**

In `app/controllers/onboard_on_rails/api/tours_controller.rb`, update the `index` action:

```ruby
def index
  matcher = TourMatcher.new(
    user: current_user,
    url: params[:url],
    session_id: params[:session_id],
    device_type: params[:device_type]
  )
  tour = matcher.match

  if tour
    completion = Completion.find_by(tour: tour, user_id: current_user.id)
    render json: {
      tour: serialize_tour(tour, matcher.current_step_index, completion)
    }
  else
    render json: { tour: nil }
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec rspec spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add app/controllers/onboard_on_rails/api/tours_controller.rb spec/controllers/onboard_on_rails/api/tours_controller_spec.rb
git commit -m "feat: pass device_type param through API to TourMatcher"
```

---

### Task 4: Admin — form, controller, locales

**Files:**
- Modify: `app/controllers/onboard_on_rails/admin/tours_controller.rb`
- Modify: `app/views/onboard_on_rails/admin/tours/_form.html.erb`
- Modify: `config/locales/en.yml`
- Modify: `config/locales/ru.yml`

- [ ] **Step 1: Add `:device_type` to permitted params**

In `app/controllers/onboard_on_rails/admin/tours_controller.rb`, update `tour_params`:

```ruby
def tour_params
  permitted = params.require(:tour).permit(
    :name, :description, :status, :trigger_type, :trigger_event,
    :frequency, :theme, :priority, :schedule_start, :schedule_end,
    :ab_test_id, :ab_test_group, :device_type,
    style_overrides: {}, segment_rules: {}
  )
  # ... rest unchanged
end
```

- [ ] **Step 2: Add select field to the form**

In `app/views/onboard_on_rails/admin/tours/_form.html.erb`, add after the `url_pattern` form group (after line 43):

```erb
<div class="oor-form-group">
  <%= f.label :device_type, t("onboard_on_rails.admin.tours.form.labels.device_type") %>
  <%= f.select :device_type, OnboardOnRails::Tour::DEVICE_TYPES.map { |dt| [t("onboard_on_rails.device_types.#{dt}"), dt] }, {}, {} %>
  <div class="oor-form-hint"><%= t("onboard_on_rails.admin.tours.form.hints.device_type") %></div>
</div>
```

- [ ] **Step 3: Add English translations**

In `config/locales/en.yml`, add under `onboard_on_rails.admin.tours.form.labels`:

```yaml
device_type: "Device Type"
```

Add under `onboard_on_rails.admin.tours.form.hints`:

```yaml
device_type: "Show this tour only on specific device types."
```

Add at the top level under `onboard_on_rails` (alongside `statuses`, `trigger_types`, etc.):

```yaml
device_types:
  all: "All Devices"
  desktop: "Desktop"
  mobile: "Mobile"
```

- [ ] **Step 4: Add Russian translations**

In `config/locales/ru.yml`, add under `onboard_on_rails.admin.tours.form.labels`:

```yaml
device_type: "Тип устройства"
```

Add under `onboard_on_rails.admin.tours.form.hints`:

```yaml
device_type: "Показывать тур только на определённых типах устройств."
```

Add at the top level under `onboard_on_rails` (alongside `statuses`, `trigger_types`, etc.):

```yaml
device_types:
  all: "Все устройства"
  desktop: "Десктоп"
  mobile: "Мобильные устройства"
```

- [ ] **Step 5: Commit**

```bash
git add app/controllers/onboard_on_rails/admin/tours_controller.rb app/views/onboard_on_rails/admin/tours/_form.html.erb config/locales/en.yml config/locales/ru.yml
git commit -m "feat: add device_type select to admin tour form"
```

---

### Task 5: Client JS — send device_type in API request

**Files:**
- Modify: `app/assets/javascripts/onboard_on_rails/client.js`

- [ ] **Step 1: Update `fetchTours` to include device_type param**

In `app/assets/javascripts/onboard_on_rails/client.js`, update the `fetchTours` method in `ApiClient` (around line 20):

```javascript
async fetchTours(url, sessionId) {
  if (!this.getUserId()) return null;
  const mountPath = this.getMountPath();
  const deviceType = window.innerWidth < 768 ? "mobile" : "desktop";
  const params = new URLSearchParams({ url, device_type: deviceType });
  if (sessionId) params.append("session_id", sessionId);
  const response = await fetch(`${mountPath}/api/tours?${params}`, { headers: { "Accept": "application/json" } });
  if (!response.ok) return null;
  const data = await response.json();
  return data.tour;
},
```

The only change is adding the `deviceType` variable and adding `device_type: deviceType` to `URLSearchParams`.

- [ ] **Step 2: Commit**

```bash
git add app/assets/javascripts/onboard_on_rails/client.js
git commit -m "feat: send device_type param from client to API"
```

---

### Task 6: Run full test suite

- [ ] **Step 1: Run all tests**

Run: `bundle exec rspec`
Expected: ALL PASS (all ~80+ examples)

- [ ] **Step 2: Verify no regressions**

Check output for 0 failures, 0 errors.
