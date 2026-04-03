# OnboardOnRails Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Rails engine gem that provides a universal onboarding/announcement tour system with a full admin panel, targeting engine, and client-side tour player.

**Architecture:** Monolithic mountable Rails engine. Admin panel built with ERB + Hotwire. Client-side tour player in vanilla JS. Data stored in host app's DB via engine migrations. JSON API connects client JS to server.

**Tech Stack:** Ruby/Rails engine, ERB, Hotwire (Turbo + Stimulus), vanilla JS, CSS custom properties, PostgreSQL (jsonb)

**Spec:** `docs/superpowers/specs/2026-04-03-onboard-on-rails-design.md`

---

## File Structure

```
onboard_on_rails/
├── onboard_on_rails.gemspec
├── Gemfile
├── Rakefile
├── README.md
├── lib/
│   ├── onboard_on_rails.rb                          # Gem entry point, configure method
│   └── onboard_on_rails/
│       ├── engine.rb                                 # Rails::Engine subclass
│       ├── configuration.rb                          # Config DSL
│       └── version.rb                                # VERSION constant
├── app/
│   ├── models/onboard_on_rails/
│   │   ├── tour.rb                                   # Tour model + scopes + URL matching
│   │   ├── step.rb                                   # Step model + ordering
│   │   ├── completion.rb                             # Completion tracking model
│   │   ├── event.rb                                  # Custom event model
│   │   └── concerns/
│   │       ├── url_matchable.rb                      # URL glob/regex matching logic
│   │       └── segment_evaluator.rb                  # Segment rule evaluation logic
│   ├── controllers/onboard_on_rails/
│   │   ├── application_controller.rb                 # Base controller
│   │   ├── admin/
│   │   │   ├── base_controller.rb                    # Admin auth guard
│   │   │   ├── tours_controller.rb                   # Tours CRUD
│   │   │   ├── steps_controller.rb                   # Steps CRUD (nested under tour)
│   │   │   └── stats_controller.rb                   # Tour analytics
│   │   ├── api/
│   │   │   ├── base_controller.rb                    # API base (JSON, auth)
│   │   │   ├── tours_controller.rb                   # GET matching tours
│   │   │   ├── completions_controller.rb             # POST completion updates
│   │   │   └── events_controller.rb                  # POST custom events
│   │   └── selector_picker_controller.rb             # Iframe proxy for visual picker
│   ├── views/
│   │   ├── layouts/onboard_on_rails/
│   │   │   └── admin.html.erb                        # Admin layout
│   │   └── onboard_on_rails/admin/
│   │       ├── tours/
│   │       │   ├── index.html.erb                    # Tours list
│   │       │   ├── new.html.erb                      # New tour form
│   │       │   ├── edit.html.erb                     # Edit tour (two-panel)
│   │       │   ├── _form.html.erb                    # Tour form partial
│   │       │   └── _tour.html.erb                    # Tour row partial (turbo)
│   │       ├── steps/
│   │       │   ├── edit.html.erb                     # Step editor with live preview
│   │       │   ├── _form.html.erb                    # Step form partial
│   │       │   ├── _step.html.erb                    # Step row partial (turbo)
│   │       │   └── _preview.html.erb                 # Live preview partial
│   │       ├── stats/
│   │       │   └── show.html.erb                     # Tour stats page
│   │       └── selector_picker/
│   │           └── show.html.erb                     # Picker iframe page
│   ├── helpers/onboard_on_rails/
│   │   ├── application_helper.rb                     # Shared helpers
│   │   ├── admin_helper.rb                           # Admin view helpers
│   │   └── meta_tags_helper.rb                       # onboard_on_rails_meta_tags
│   ├── assets/
│   │   ├── javascripts/onboard_on_rails/
│   │   │   ├── admin.js                              # Admin entry point (imports Stimulus)
│   │   │   ├── admin/
│   │   │   │   ├── step_preview_controller.js        # Live preview Stimulus controller
│   │   │   │   ├── selector_picker_controller.js     # Visual picker Stimulus controller
│   │   │   │   ├── segment_rules_controller.js       # Rule builder Stimulus controller
│   │   │   │   └── sortable_controller.js            # Drag-to-reorder steps
│   │   │   ├── client.js                             # Client entry point (auto-init)
│   │   │   └── client/
│   │   │       ├── tour_manager.js                   # Fetch + lifecycle
│   │   │       ├── tour_renderer.js                  # Overlay + tooltip rendering
│   │   │       ├── positioning_engine.js             # Tooltip placement math
│   │   │       ├── dom_observer.js                   # MutationObserver + Turbo events
│   │   │       ├── api_client.js                     # Fetch wrapper
│   │   │       ├── theme_engine.js                   # CSS custom properties
│   │   │       └── selector_generator.js             # Generate CSS selector from element
│   │   └── stylesheets/onboard_on_rails/
│   │       ├── admin.css                             # Admin panel styles
│   │       └── client.css                            # Tour overlay + theme presets
│   └── services/onboard_on_rails/
│       ├── tour_matcher.rb                           # Finds matching tours for user+URL
│       ├── ab_assigner.rb                            # Deterministic A/B group assignment
│       └── stats_calculator.rb                       # Completion rates, drop-off, A/B stats
├── config/
│   └── routes.rb                                     # Engine routes
├── db/migrate/
│   ├── 001_create_onboard_on_rails_tours.rb
│   ├── 002_create_onboard_on_rails_steps.rb
│   ├── 003_create_onboard_on_rails_completions.rb
│   └── 004_create_onboard_on_rails_events.rb
├── spec/
│   ├── spec_helper.rb
│   ├── rails_helper.rb
│   ├── dummy/                                        # Dummy Rails app for testing
│   │   ├── config/
│   │   ├── app/models/user.rb
│   │   └── db/schema.rb
│   ├── models/onboard_on_rails/
│   │   ├── tour_spec.rb
│   │   ├── step_spec.rb
│   │   ├── completion_spec.rb
│   │   └── event_spec.rb
│   ├── services/onboard_on_rails/
│   │   ├── tour_matcher_spec.rb
│   │   ├── ab_assigner_spec.rb
│   │   └── stats_calculator_spec.rb
│   ├── concerns/
│   │   ├── url_matchable_spec.rb
│   │   └── segment_evaluator_spec.rb
│   ├── controllers/onboard_on_rails/
│   │   ├── admin/tours_controller_spec.rb
│   │   ├── admin/steps_controller_spec.rb
│   │   ├── api/tours_controller_spec.rb
│   │   ├── api/completions_controller_spec.rb
│   │   └── api/events_controller_spec.rb
│   └── factories/
│       ├── tours.rb
│       ├── steps.rb
│       ├── completions.rb
│       └── events.rb
└── docs/superpowers/
    ├── specs/2026-04-03-onboard-on-rails-design.md
    └── plans/2026-04-03-onboard-on-rails.md          # This file
```

---

## Task 1: Gem Scaffold & Engine Setup

**Files:**
- Create: `onboard_on_rails.gemspec`
- Create: `Gemfile`
- Create: `Rakefile`
- Create: `lib/onboard_on_rails.rb`
- Create: `lib/onboard_on_rails/version.rb`
- Create: `lib/onboard_on_rails/engine.rb`
- Create: `lib/onboard_on_rails/configuration.rb`
- Create: `app/controllers/onboard_on_rails/application_controller.rb`

- [ ] **Step 1: Initialize gem structure**

```bash
cd /Users/aleksandrsvajkin/develop/onboard_on_rails
```

Create `lib/onboard_on_rails/version.rb`:
```ruby
module OnboardOnRails
  VERSION = "0.1.0"
end
```

Create `lib/onboard_on_rails/configuration.rb`:
```ruby
module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :user_attributes, :current_user_method

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @user_attributes = ->(user) { {} }
      @current_user_method = :current_user
    end
  end
end
```

Create `lib/onboard_on_rails/engine.rb`:
```ruby
module OnboardOnRails
  class Engine < ::Rails::Engine
    isolate_namespace OnboardOnRails

    initializer "onboard_on_rails.assets.precompile" do |app|
      app.config.assets.precompile += %w[
        onboard_on_rails/admin.js
        onboard_on_rails/admin.css
        onboard_on_rails/client.js
        onboard_on_rails/client.css
      ]
    end
  end
end
```

Create `lib/onboard_on_rails.rb`:
```ruby
require "onboard_on_rails/version"
require "onboard_on_rails/configuration"
require "onboard_on_rails/engine"

module OnboardOnRails
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def track_event(user, name, payload = {})
      OnboardOnRails::Event.create!(
        user_id: user.id,
        name: name,
        payload: payload
      )
    end
  end
end
```

Create `onboard_on_rails.gemspec`:
```ruby
require_relative "lib/onboard_on_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "onboard_on_rails"
  spec.version     = OnboardOnRails::VERSION
  spec.authors     = ["Aleksandr Svajkin"]
  spec.summary     = "Universal onboarding tour engine for Rails"
  spec.description = "A Rails engine that adds an admin panel for creating and managing onboarding tours with visual element picker, advanced targeting, and A/B testing."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "pg"
end
```

Create `Gemfile`:
```ruby
source "https://rubygems.org"
gemspec

gem "pg"
gem "sprockets-rails"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "debug"
end
```

Create `Rakefile`:
```ruby
require "bundler/setup"
require "bundler/gem_tasks"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"
load "rails/tasks/statistics.rake"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec
```

Create `app/controllers/onboard_on_rails/application_controller.rb`:
```ruby
module OnboardOnRails
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  end
end
```

- [ ] **Step 2: Run `bundle install`**

```bash
cd /Users/aleksandrsvajkin/develop/onboard_on_rails
bundle install
```

Expected: Successful bundle install, Gemfile.lock created.

- [ ] **Step 3: Commit**

```bash
git init
git add -A
git commit -m "feat: scaffold OnboardOnRails gem with engine, configuration, and gemspec"
```

---

## Task 2: Dummy App & Test Infrastructure

**Files:**
- Create: `spec/dummy/` (minimal Rails app)
- Create: `spec/spec_helper.rb`
- Create: `spec/rails_helper.rb`
- Create: `spec/factories/tours.rb`
- Create: `spec/factories/steps.rb`
- Create: `spec/factories/completions.rb`
- Create: `spec/factories/events.rb`

- [ ] **Step 1: Generate dummy Rails app**

```bash
cd /Users/aleksandrsvajkin/develop/onboard_on_rails
rails plugin new . --mountable --skip-test --dummy-path=spec/dummy --database=postgresql --skip-git --force
```

This will generate the dummy app structure. We need to override some generated files that conflict with our setup. After generation, ensure `spec/dummy/config/routes.rb` mounts the engine:

```ruby
Rails.application.routes.draw do
  mount OnboardOnRails::Engine, at: "/onboard"
end
```

- [ ] **Step 2: Create the dummy User model**

Create `spec/dummy/app/models/user.rb`:
```ruby
class User < ApplicationRecord
  def admin?
    role == "admin"
  end
end
```

Create migration `spec/dummy/db/migrate/001_create_users.rb`:
```ruby
class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :role, default: "user"
      t.string :plan, default: "free"
      t.timestamps
    end
  end
end
```

- [ ] **Step 3: Set up RSpec**

Create `spec/spec_helper.rb`:
```ruby
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
```

Create `spec/rails_helper.rb`:
```ruby
require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "dummy/config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "factory_bot_rails"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
end
```

- [ ] **Step 4: Create factories**

Create `spec/factories/tours.rb`:
```ruby
FactoryBot.define do
  factory :tour, class: "OnboardOnRails::Tour" do
    sequence(:name) { |n| "Tour #{n}" }
    description { "A test tour" }
    status { "active" }
    trigger_type { "auto" }
    url_pattern { ["/dashboard/*"] }
    frequency { "once" }
    theme { "tooltip" }
    priority { 0 }

    trait :draft do
      status { "draft" }
    end

    trait :archived do
      status { "archived" }
    end

    trait :event_triggered do
      trigger_type { "event" }
      trigger_event { "first_project_created" }
    end

    trait :with_schedule do
      schedule_start { 1.day.ago }
      schedule_end { 1.day.from_now }
    end

    trait :with_ab_test do
      ab_test_id { "experiment_1" }
      ab_test_group { "A" }
    end
  end
end
```

Create `spec/factories/steps.rb`:
```ruby
FactoryBot.define do
  factory :step, class: "OnboardOnRails::Step" do
    tour
    sequence(:position) { |n| n }
    title { "Step title" }
    body { "Step body text" }
    selector { "#main-header" }
    placement { "bottom" }
    action_type { "next" }
  end
end
```

Create `spec/factories/completions.rb`:
```ruby
FactoryBot.define do
  factory :completion, class: "OnboardOnRails::Completion" do
    tour
    user_id { 1 }
    status { "in_progress" }
    started_at { Time.current }
    session_id { SecureRandom.hex(16) }
  end
end
```

Create `spec/factories/events.rb`:
```ruby
FactoryBot.define do
  factory :event, class: "OnboardOnRails::Event" do
    user_id { 1 }
    name { "first_project_created" }
    payload { {} }
  end
end
```

- [ ] **Step 5: Create and migrate the dummy database**

```bash
cd /Users/aleksandrsvajkin/develop/onboard_on_rails
cd spec/dummy && RAILS_ENV=test rails db:create db:migrate && cd ../..
```

Expected: Database created, no errors.

- [ ] **Step 6: Verify RSpec runs**

```bash
bundle exec rspec
```

Expected: 0 examples, 0 failures (green run, no errors loading).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add dummy app, RSpec setup, and factories"
```

---

## Task 3: Database Migrations

**Files:**
- Create: `db/migrate/001_create_onboard_on_rails_tours.rb`
- Create: `db/migrate/002_create_onboard_on_rails_steps.rb`
- Create: `db/migrate/003_create_onboard_on_rails_completions.rb`
- Create: `db/migrate/004_create_onboard_on_rails_events.rb`

- [ ] **Step 1: Create tours migration**

Create `db/migrate/001_create_onboard_on_rails_tours.rb`:
```ruby
class CreateOnboardOnRailsTours < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_tours do |t|
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.string :trigger_type, null: false, default: "auto"
      t.string :trigger_event
      t.jsonb :url_pattern, null: false, default: []
      t.jsonb :segment_rules, null: false, default: {}
      t.datetime :schedule_start
      t.datetime :schedule_end
      t.string :frequency, null: false, default: "once"
      t.string :ab_test_group
      t.string :ab_test_id
      t.string :theme, null: false, default: "tooltip"
      t.jsonb :style_overrides, null: false, default: {}
      t.integer :priority, null: false, default: 0
      t.timestamps
    end

    add_index :onboard_on_rails_tours, :status
    add_index :onboard_on_rails_tours, :ab_test_id
  end
end
```

- [ ] **Step 2: Create steps migration**

Create `db/migrate/002_create_onboard_on_rails_steps.rb`:
```ruby
class CreateOnboardOnRailsSteps < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_steps do |t|
      t.references :tour, null: false, foreign_key: { to_table: :onboard_on_rails_tours }
      t.integer :position, null: false, default: 0
      t.string :title, null: false
      t.text :body
      t.string :selector, null: false
      t.string :placement, null: false, default: "bottom"
      t.string :url_pattern
      t.jsonb :style_overrides, null: false, default: {}
      t.string :action_type, null: false, default: "next"
      t.string :action_value
      t.string :wait_for_selector
      t.timestamps
    end

    add_index :onboard_on_rails_steps, [:tour_id, :position]
  end
end
```

- [ ] **Step 3: Create completions migration**

Create `db/migrate/003_create_onboard_on_rails_completions.rb`:
```ruby
class CreateOnboardOnRailsCompletions < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_completions do |t|
      t.references :tour, null: false, foreign_key: { to_table: :onboard_on_rails_tours }
      t.bigint :user_id, null: false
      t.references :step, foreign_key: { to_table: :onboard_on_rails_steps }
      t.string :status, null: false, default: "in_progress"
      t.string :ab_group
      t.string :session_id
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :onboard_on_rails_completions, [:tour_id, :user_id]
    add_index :onboard_on_rails_completions, :user_id
    add_index :onboard_on_rails_completions, :session_id
  end
end
```

- [ ] **Step 4: Create events migration**

Create `db/migrate/004_create_onboard_on_rails_events.rb`:
```ruby
class CreateOnboardOnRailsEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_events do |t|
      t.bigint :user_id, null: false
      t.string :name, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :onboard_on_rails_events, [:user_id, :name]
    add_index :onboard_on_rails_events, :name
  end
end
```

- [ ] **Step 5: Copy migrations to dummy and run them**

```bash
cd /Users/aleksandrsvajkin/develop/onboard_on_rails/spec/dummy
rails onboard_on_rails:install:migrations
RAILS_ENV=test rails db:migrate
cd ../..
```

Expected: All 4 migrations run, tables created.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add database migrations for tours, steps, completions, events"
```

---

## Task 4: Models — Tour & Step

**Files:**
- Create: `app/models/onboard_on_rails/tour.rb`
- Create: `app/models/onboard_on_rails/step.rb`
- Test: `spec/models/onboard_on_rails/tour_spec.rb`
- Test: `spec/models/onboard_on_rails/step_spec.rb`

- [ ] **Step 1: Write Tour model tests**

Create `spec/models/onboard_on_rails/tour_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Tour, type: :model do
  describe "validations" do
    it "requires a name" do
      tour = build(:tour, name: nil)
      expect(tour).not_to be_valid
      expect(tour.errors[:name]).to include("can't be blank")
    end

    it "validates status inclusion" do
      tour = build(:tour, status: "invalid")
      expect(tour).not_to be_valid
    end

    it "validates trigger_type inclusion" do
      tour = build(:tour, trigger_type: "invalid")
      expect(tour).not_to be_valid
    end

    it "validates frequency inclusion" do
      tour = build(:tour, frequency: "invalid")
      expect(tour).not_to be_valid
    end

    it "validates theme inclusion" do
      tour = build(:tour, theme: "invalid")
      expect(tour).not_to be_valid
    end

    it "requires trigger_event when trigger_type is event" do
      tour = build(:tour, trigger_type: "event", trigger_event: nil)
      expect(tour).not_to be_valid
      expect(tour.errors[:trigger_event]).to include("can't be blank")
    end

    it "is valid with all required attributes" do
      tour = build(:tour)
      expect(tour).to be_valid
    end
  end

  describe "scopes" do
    it ".active returns only active tours" do
      active = create(:tour, status: "active")
      create(:tour, :draft)
      create(:tour, :archived)

      expect(described_class.active).to eq([active])
    end

    it ".scheduled_now returns tours within schedule window" do
      in_window = create(:tour, :with_schedule)
      past = create(:tour, schedule_start: 3.days.ago, schedule_end: 2.days.ago)
      future = create(:tour, schedule_start: 2.days.from_now, schedule_end: 3.days.from_now)
      no_schedule = create(:tour, schedule_start: nil, schedule_end: nil)

      result = described_class.scheduled_now
      expect(result).to include(in_window, no_schedule)
      expect(result).not_to include(past, future)
    end

    it ".by_priority orders by priority descending" do
      low = create(:tour, priority: 1)
      high = create(:tour, priority: 10)
      mid = create(:tour, priority: 5)

      expect(described_class.by_priority).to eq([high, mid, low])
    end
  end

  describe "associations" do
    it "has many steps ordered by position" do
      tour = create(:tour)
      step2 = create(:step, tour: tour, position: 2)
      step1 = create(:step, tour: tour, position: 1)

      expect(tour.steps).to eq([step1, step2])
    end

    it "has many completions" do
      tour = create(:tour)
      completion = create(:completion, tour: tour)

      expect(tour.completions).to eq([completion])
    end

    it "destroys steps when destroyed" do
      tour = create(:tour)
      create(:step, tour: tour)

      expect { tour.destroy }.to change(OnboardOnRails::Step, :count).by(-1)
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bundle exec rspec spec/models/onboard_on_rails/tour_spec.rb
```

Expected: FAIL — model not defined.

- [ ] **Step 3: Write Tour model**

Create `app/models/onboard_on_rails/tour.rb`:
```ruby
module OnboardOnRails
  class Tour < ApplicationRecord
    self.table_name = "onboard_on_rails_tours"

    STATUSES = %w[draft active archived].freeze
    TRIGGER_TYPES = %w[auto event manual].freeze
    FREQUENCIES = %w[once every_session always].freeze
    THEMES = %w[tooltip modal banner slideout].freeze

    has_many :steps, -> { order(:position) }, dependent: :destroy
    has_many :completions, dependent: :destroy

    validates :name, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :trigger_type, inclusion: { in: TRIGGER_TYPES }
    validates :frequency, inclusion: { in: FREQUENCIES }
    validates :theme, inclusion: { in: THEMES }
    validates :trigger_event, presence: true, if: -> { trigger_type == "event" }

    scope :active, -> { where(status: "active") }
    scope :scheduled_now, -> {
      now = Time.current
      where("schedule_start IS NULL OR schedule_start <= ?", now)
        .where("schedule_end IS NULL OR schedule_end >= ?", now)
    }
    scope :by_priority, -> { order(priority: :desc) }
  end
end
```

Create `app/models/onboard_on_rails/application_record.rb`:
```ruby
module OnboardOnRails
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
```

- [ ] **Step 4: Run Tour tests to verify they pass**

```bash
bundle exec rspec spec/models/onboard_on_rails/tour_spec.rb
```

Expected: All pass (green).

- [ ] **Step 5: Write Step model tests**

Create `spec/models/onboard_on_rails/step_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Step, type: :model do
  describe "validations" do
    it "requires a title" do
      step = build(:step, title: nil)
      expect(step).not_to be_valid
    end

    it "requires a selector" do
      step = build(:step, selector: nil)
      expect(step).not_to be_valid
    end

    it "validates placement inclusion" do
      step = build(:step, placement: "diagonal")
      expect(step).not_to be_valid
    end

    it "validates action_type inclusion" do
      step = build(:step, action_type: "invalid")
      expect(step).not_to be_valid
    end

    it "is valid with all required attributes" do
      step = build(:step)
      expect(step).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a tour" do
      step = create(:step)
      expect(step.tour).to be_a(OnboardOnRails::Tour)
    end
  end
end
```

- [ ] **Step 6: Run Step tests to verify they fail**

```bash
bundle exec rspec spec/models/onboard_on_rails/step_spec.rb
```

Expected: FAIL — Step model not defined.

- [ ] **Step 7: Write Step model**

Create `app/models/onboard_on_rails/step.rb`:
```ruby
module OnboardOnRails
  class Step < ApplicationRecord
    self.table_name = "onboard_on_rails_steps"

    PLACEMENTS = %w[top bottom left right center].freeze
    ACTION_TYPES = %w[next redirect custom_event].freeze

    belongs_to :tour

    validates :title, presence: true
    validates :selector, presence: true
    validates :placement, inclusion: { in: PLACEMENTS }
    validates :action_type, inclusion: { in: ACTION_TYPES }
  end
end
```

- [ ] **Step 8: Run all model tests**

```bash
bundle exec rspec spec/models/
```

Expected: All pass.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: add Tour and Step models with validations and scopes"
```

---

## Task 5: Models — Completion & Event

**Files:**
- Create: `app/models/onboard_on_rails/completion.rb`
- Create: `app/models/onboard_on_rails/event.rb`
- Test: `spec/models/onboard_on_rails/completion_spec.rb`
- Test: `spec/models/onboard_on_rails/event_spec.rb`

- [ ] **Step 1: Write Completion model tests**

Create `spec/models/onboard_on_rails/completion_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Completion, type: :model do
  describe "validations" do
    it "requires a user_id" do
      completion = build(:completion, user_id: nil)
      expect(completion).not_to be_valid
    end

    it "validates status inclusion" do
      completion = build(:completion, status: "invalid")
      expect(completion).not_to be_valid
    end

    it "is valid with required attributes" do
      completion = build(:completion)
      expect(completion).to be_valid
    end
  end

  describe "scopes" do
    it ".for_user returns completions for a specific user" do
      c1 = create(:completion, user_id: 1)
      create(:completion, user_id: 2)

      expect(described_class.for_user(1)).to eq([c1])
    end

    it ".completed returns only completed" do
      completed = create(:completion, status: "completed")
      create(:completion, status: "in_progress")

      expect(described_class.completed).to eq([completed])
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/models/onboard_on_rails/completion_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write Completion model**

Create `app/models/onboard_on_rails/completion.rb`:
```ruby
module OnboardOnRails
  class Completion < ApplicationRecord
    self.table_name = "onboard_on_rails_completions"

    STATUSES = %w[in_progress completed dismissed].freeze

    belongs_to :tour
    belongs_to :step, optional: true

    validates :user_id, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :completed, -> { where(status: "completed") }
    scope :dismissed, -> { where(status: "dismissed") }
  end
end
```

- [ ] **Step 4: Run Completion tests**

```bash
bundle exec rspec spec/models/onboard_on_rails/completion_spec.rb
```

Expected: All pass.

- [ ] **Step 5: Write Event model tests**

Create `spec/models/onboard_on_rails/event_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Event, type: :model do
  describe "validations" do
    it "requires a user_id" do
      event = build(:event, user_id: nil)
      expect(event).not_to be_valid
    end

    it "requires a name" do
      event = build(:event, name: nil)
      expect(event).not_to be_valid
    end

    it "is valid with required attributes" do
      event = build(:event)
      expect(event).to be_valid
    end
  end

  describe "scopes" do
    it ".for_user returns events for a specific user" do
      e1 = create(:event, user_id: 1)
      create(:event, user_id: 2)

      expect(described_class.for_user(1)).to eq([e1])
    end

    it ".by_name returns events with specific name" do
      match = create(:event, name: "signup")
      create(:event, name: "purchase")

      expect(described_class.by_name("signup")).to eq([match])
    end
  end
end
```

- [ ] **Step 6: Run to verify failures**

```bash
bundle exec rspec spec/models/onboard_on_rails/event_spec.rb
```

Expected: FAIL.

- [ ] **Step 7: Write Event model**

Create `app/models/onboard_on_rails/event.rb`:
```ruby
module OnboardOnRails
  class Event < ApplicationRecord
    self.table_name = "onboard_on_rails_events"

    validates :user_id, presence: true
    validates :name, presence: true

    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :by_name, ->(name) { where(name: name) }
  end
end
```

- [ ] **Step 8: Run all model tests**

```bash
bundle exec rspec spec/models/
```

Expected: All pass.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: add Completion and Event models"
```

---

## Task 6: URL Matching Concern

**Files:**
- Create: `app/models/onboard_on_rails/concerns/url_matchable.rb`
- Test: `spec/concerns/url_matchable_spec.rb`

- [ ] **Step 1: Write URL matching tests**

Create `spec/concerns/url_matchable_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Concerns::UrlMatchable do
  let(:tour_class) { OnboardOnRails::Tour }

  describe "#matches_url?" do
    it "matches exact URL" do
      tour = build(:tour, url_pattern: ["/dashboard"])
      expect(tour.matches_url?("/dashboard")).to be true
    end

    it "matches glob with wildcard" do
      tour = build(:tour, url_pattern: ["/dashboard/*"])
      expect(tour.matches_url?("/dashboard/stats")).to be true
      expect(tour.matches_url?("/settings")).to be false
    end

    it "matches double wildcard for nested paths" do
      tour = build(:tour, url_pattern: ["/projects/**"])
      expect(tour.matches_url?("/projects/1/edit")).to be true
      expect(tour.matches_url?("/projects")).to be false
    end

    it "matches any of multiple patterns" do
      tour = build(:tour, url_pattern: ["/dashboard", "/home"])
      expect(tour.matches_url?("/dashboard")).to be true
      expect(tour.matches_url?("/home")).to be true
      expect(tour.matches_url?("/settings")).to be false
    end

    it "matches regex patterns (wrapped in slashes)" do
      tour = build(:tour, url_pattern: ['/projects/\d+/edit'])
      expect(tour.matches_url?("/projects/123/edit")).to be true
      expect(tour.matches_url?("/projects/abc/edit")).to be false
    end

    it "returns true when url_pattern is empty (matches all)" do
      tour = build(:tour, url_pattern: [])
      expect(tour.matches_url?("/anything")).to be true
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/concerns/url_matchable_spec.rb
```

Expected: FAIL — concern not defined.

- [ ] **Step 3: Write UrlMatchable concern**

Create `app/models/onboard_on_rails/concerns/url_matchable.rb`:
```ruby
module OnboardOnRails
  module Concerns
    module UrlMatchable
      extend ActiveSupport::Concern

      def matches_url?(url)
        patterns = url_pattern.is_a?(Array) ? url_pattern : [url_pattern]
        return true if patterns.empty?

        patterns.any? { |pattern| url_matches_pattern?(url, pattern.to_s) }
      end

      private

      def url_matches_pattern?(url, pattern)
        return true if pattern.blank?

        if pattern.include?("\\")
          # Treat as regex
          Regexp.new("\\A#{pattern}\\z").match?(url)
        else
          # Treat as glob
          regex = glob_to_regex(pattern)
          regex.match?(url)
        end
      end

      def glob_to_regex(glob)
        escaped = Regexp.escape(glob)
        # ** matches any path depth
        escaped = escaped.gsub("\\*\\*", "DOUBLE_STAR")
        # * matches single path segment
        escaped = escaped.gsub("\\*", "[^/]*")
        escaped = escaped.gsub("DOUBLE_STAR", ".*")
        Regexp.new("\\A#{escaped}\\z")
      end
    end
  end
end
```

Include in Tour model — add to `app/models/onboard_on_rails/tour.rb` after `self.table_name`:
```ruby
include Concerns::UrlMatchable
```

- [ ] **Step 4: Run tests**

```bash
bundle exec rspec spec/concerns/url_matchable_spec.rb
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add UrlMatchable concern for glob and regex URL matching"
```

---

## Task 7: Segment Evaluator Concern

**Files:**
- Create: `app/models/onboard_on_rails/concerns/segment_evaluator.rb`
- Test: `spec/concerns/segment_evaluator_spec.rb`

- [ ] **Step 1: Write segment evaluator tests**

Create `spec/concerns/segment_evaluator_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Concerns::SegmentEvaluator do
  describe "#matches_segment?" do
    let(:user_attributes) { { role: "admin", plan: "pro", signed_up_at: "2026-01-15" } }

    it "returns true when segment_rules is empty" do
      tour = build(:tour, segment_rules: {})
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "matches equality condition" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "admin" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "rejects when equality fails" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "user" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be false
    end

    it "matches not_eq operator" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "not_eq", "value" => "user" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "matches in operator" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "plan", "operator" => "in", "value" => ["pro", "enterprise"] }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "matches gt operator for dates" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "signed_up_at", "operator" => "gt", "value" => "2026-01-01" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "handles AND logic — all conditions must match" do
      tour = build(:tour, segment_rules: {
        "conditions" => [
          { "attribute" => "role", "operator" => "eq", "value" => "admin" },
          { "attribute" => "plan", "operator" => "eq", "value" => "free" }
        ],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be false
    end

    it "handles OR logic — any condition can match" do
      tour = build(:tour, segment_rules: {
        "conditions" => [
          { "attribute" => "role", "operator" => "eq", "value" => "user" },
          { "attribute" => "plan", "operator" => "eq", "value" => "pro" }
        ],
        "logic" => "or"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/concerns/segment_evaluator_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write SegmentEvaluator concern**

Create `app/models/onboard_on_rails/concerns/segment_evaluator.rb`:
```ruby
module OnboardOnRails
  module Concerns
    module SegmentEvaluator
      extend ActiveSupport::Concern

      def matches_segment?(user_attributes)
        rules = segment_rules
        return true if rules.blank? || rules["conditions"].blank?

        conditions = rules["conditions"]
        logic = rules.fetch("logic", "and")

        if logic == "or"
          conditions.any? { |c| evaluate_condition(c, user_attributes) }
        else
          conditions.all? { |c| evaluate_condition(c, user_attributes) }
        end
      end

      private

      def evaluate_condition(condition, user_attributes)
        attr_name = condition["attribute"]
        operator = condition["operator"]
        expected = condition["value"]
        actual = user_attributes[attr_name.to_sym]

        return false if actual.nil?

        case operator
        when "eq"
          actual.to_s == expected.to_s
        when "not_eq"
          actual.to_s != expected.to_s
        when "in"
          Array(expected).map(&:to_s).include?(actual.to_s)
        when "not_in"
          !Array(expected).map(&:to_s).include?(actual.to_s)
        when "gt"
          actual.to_s > expected.to_s
        when "lt"
          actual.to_s < expected.to_s
        when "gte"
          actual.to_s >= expected.to_s
        when "lte"
          actual.to_s <= expected.to_s
        else
          false
        end
      end
    end
  end
end
```

Include in Tour model — add to `app/models/onboard_on_rails/tour.rb`:
```ruby
include Concerns::SegmentEvaluator
```

- [ ] **Step 4: Run tests**

```bash
bundle exec rspec spec/concerns/segment_evaluator_spec.rb
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add SegmentEvaluator concern for user targeting rules"
```

---

## Task 8: A/B Assigner Service

**Files:**
- Create: `app/services/onboard_on_rails/ab_assigner.rb`
- Test: `spec/services/onboard_on_rails/ab_assigner_spec.rb`

- [ ] **Step 1: Write A/B assigner tests**

Create `spec/services/onboard_on_rails/ab_assigner_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::AbAssigner do
  describe ".assign_group" do
    it "returns nil when tour has no ab_test_id" do
      tour = build(:tour, ab_test_id: nil)
      expect(described_class.assign_group(user_id: 1, tour: tour)).to be_nil
    end

    it "returns a consistent group for the same user + experiment" do
      tour_a = build(:tour, ab_test_id: "exp1", ab_test_group: "A")
      tour_b = build(:tour, ab_test_id: "exp1", ab_test_group: "B")

      group1 = described_class.assign_group(user_id: 42, tour: tour_a, groups: %w[A B])
      group2 = described_class.assign_group(user_id: 42, tour: tour_b, groups: %w[A B])

      expect(group1).to eq(group2)
    end

    it "distributes users roughly evenly across groups" do
      counts = Hash.new(0)
      1000.times do |i|
        tour = build(:tour, ab_test_id: "exp1")
        group = described_class.assign_group(user_id: i, tour: tour, groups: %w[A B])
        counts[group] += 1
      end

      expect(counts["A"]).to be_between(400, 600)
      expect(counts["B"]).to be_between(400, 600)
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/services/onboard_on_rails/ab_assigner_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write AbAssigner service**

Create `app/services/onboard_on_rails/ab_assigner.rb`:
```ruby
require "digest"

module OnboardOnRails
  class AbAssigner
    def self.assign_group(user_id:, tour:, groups: nil)
      return nil if tour.ab_test_id.blank?

      groups ||= OnboardOnRails::Tour
        .where(ab_test_id: tour.ab_test_id)
        .distinct
        .pluck(:ab_test_group)
        .compact

      return nil if groups.empty?

      hash = Digest::SHA256.hexdigest("#{user_id}-#{tour.ab_test_id}")
      index = hash.to_i(16) % groups.size
      groups.sort[index]
    end
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bundle exec rspec spec/services/onboard_on_rails/ab_assigner_spec.rb
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add AbAssigner service for deterministic A/B group assignment"
```

---

## Task 9: TourMatcher Service

**Files:**
- Create: `app/services/onboard_on_rails/tour_matcher.rb`
- Test: `spec/services/onboard_on_rails/tour_matcher_spec.rb`

- [ ] **Step 1: Write TourMatcher tests**

Create `spec/services/onboard_on_rails/tour_matcher_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::TourMatcher do
  let(:user) { User.create!(email: "test@test.com", role: "admin", plan: "pro") }

  before do
    OnboardOnRails.configure do |config|
      config.user_attributes = ->(u) { { role: u.role, plan: u.plan, signed_up_at: u.created_at.to_s } }
    end
  end

  describe "#match" do
    it "returns the highest priority active tour matching the URL" do
      low = create(:tour, url_pattern: ["/dashboard/*"], priority: 1)
      high = create(:tour, url_pattern: ["/dashboard/*"], priority: 10)
      create(:step, tour: low)
      create(:step, tour: high)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to eq(high)
    end

    it "excludes draft and archived tours" do
      create(:tour, :draft, url_pattern: ["/dashboard/*"])
      create(:tour, :archived, url_pattern: ["/dashboard/*"])

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "excludes tours outside schedule window" do
      create(:tour, url_pattern: ["/dashboard/*"],
        schedule_start: 2.days.from_now, schedule_end: 3.days.from_now)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "excludes tours already completed when frequency is once" do
      tour = create(:tour, url_pattern: ["/dashboard/*"], frequency: "once")
      create(:step, tour: tour)
      create(:completion, tour: tour, user_id: user.id, status: "completed")

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "includes tours with frequency always even if completed" do
      tour = create(:tour, url_pattern: ["/dashboard/*"], frequency: "always")
      create(:step, tour: tour)
      create(:completion, tour: tour, user_id: user.id, status: "completed")

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to eq(tour)
    end

    it "excludes tours when segment rules don't match" do
      tour = create(:tour, url_pattern: ["/dashboard/*"], segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "user" }],
        "logic" => "and"
      })
      create(:step, tour: tour)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "filters by A/B test group" do
      tour_a = create(:tour, url_pattern: ["/dashboard/*"], ab_test_id: "exp1", ab_test_group: "A")
      tour_b = create(:tour, url_pattern: ["/dashboard/*"], ab_test_id: "exp1", ab_test_group: "B")
      create(:step, tour: tour_a)
      create(:step, tour: tour_b)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect([tour_a, tour_b]).to include(result)
    end

    it "handles event-triggered tours" do
      tour = create(:tour, :event_triggered, url_pattern: ["/dashboard/*"])
      create(:step, tour: tour)
      create(:event, user_id: user.id, name: "first_project_created")

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to eq(tour)
    end

    it "excludes event-triggered tours when event hasn't fired" do
      tour = create(:tour, :event_triggered, url_pattern: ["/dashboard/*"])
      create(:step, tour: tour)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/services/onboard_on_rails/tour_matcher_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write TourMatcher service**

Create `app/services/onboard_on_rails/tour_matcher.rb`:
```ruby
module OnboardOnRails
  class TourMatcher
    def initialize(user:, url:, session_id: nil)
      @user = user
      @url = url
      @session_id = session_id
      @user_attributes = OnboardOnRails.configuration.user_attributes.call(user)
    end

    def match
      candidates = base_scope.to_a

      candidates = candidates.select { |t| t.matches_url?(@url) }
      candidates = candidates.select { |t| t.matches_segment?(@user_attributes) }
      candidates = candidates.reject { |t| excluded_by_frequency?(t) }
      candidates = candidates.reject { |t| excluded_by_event_trigger?(t) }
      candidates = candidates.select { |t| included_by_ab_test?(t) }

      candidates.max_by(&:priority)
    end

    private

    def base_scope
      OnboardOnRails::Tour
        .active
        .scheduled_now
        .by_priority
        .includes(:steps)
        .where("EXISTS (SELECT 1 FROM onboard_on_rails_steps WHERE onboard_on_rails_steps.tour_id = onboard_on_rails_tours.id)")
    end

    def excluded_by_frequency?(tour)
      case tour.frequency
      when "always"
        false
      when "once"
        Completion.for_user(@user.id)
          .where(tour: tour)
          .where(status: %w[completed dismissed])
          .exists?
      when "every_session"
        Completion.for_user(@user.id)
          .where(tour: tour, session_id: @session_id)
          .where(status: %w[completed dismissed])
          .exists?
      else
        false
      end
    end

    def excluded_by_event_trigger?(tour)
      return false unless tour.trigger_type == "event"

      !Event.for_user(@user.id).by_name(tour.trigger_event).exists?
    end

    def included_by_ab_test?(tour)
      return true if tour.ab_test_id.blank?

      assigned = AbAssigner.assign_group(user_id: @user.id, tour: tour)
      tour.ab_test_group == assigned
    end
  end
end
```

- [ ] **Step 4: Run tests**

```bash
bundle exec rspec spec/services/onboard_on_rails/tour_matcher_spec.rb
```

Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add TourMatcher service — finds matching tours for user + URL"
```

---

## Task 10: Engine Routes

**Files:**
- Create: `config/routes.rb`

- [ ] **Step 1: Write routes**

Create `config/routes.rb`:
```ruby
OnboardOnRails::Engine.routes.draw do
  namespace :admin do
    resources :tours do
      resources :steps, except: [:index]
      resource :stats, only: [:show]
    end
    root to: "tours#index"
  end

  namespace :api do
    resources :tours, only: [:index]
    resources :completions, only: [:create]
    resources :events, only: [:create]
  end

  get "selector_picker", to: "selector_picker#show"
end
```

- [ ] **Step 2: Verify routes load**

```bash
cd /Users/aleksandrsvajkin/develop/onboard_on_rails/spec/dummy
RAILS_ENV=test rails routes --grep onboard
cd ../..
```

Expected: Route list with admin, api, and selector_picker paths.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add engine routes for admin, API, and selector picker"
```

---

## Task 11: API Controllers

**Files:**
- Create: `app/controllers/onboard_on_rails/api/base_controller.rb`
- Create: `app/controllers/onboard_on_rails/api/tours_controller.rb`
- Create: `app/controllers/onboard_on_rails/api/completions_controller.rb`
- Create: `app/controllers/onboard_on_rails/api/events_controller.rb`
- Test: `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`
- Test: `spec/controllers/onboard_on_rails/api/completions_controller_spec.rb`
- Test: `spec/controllers/onboard_on_rails/api/events_controller_spec.rb`

- [ ] **Step 1: Write API tours controller tests**

Create `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Api::ToursController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:user) { User.create!(email: "test@test.com", role: "admin", plan: "pro") }

  before do
    OnboardOnRails.configure do |config|
      config.current_user_method = :current_user
      config.user_attributes = ->(u) { { role: u.role, plan: u.plan } }
    end
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "returns matching tour with steps as JSON" do
      tour = create(:tour, url_pattern: ["/dashboard/*"])
      step = create(:step, tour: tour, position: 1)

      get :index, params: { url: "/dashboard/home" }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tour"]["id"]).to eq(tour.id)
      expect(json["tour"]["steps"].length).to eq(1)
      expect(json["tour"]["steps"][0]["id"]).to eq(step.id)
    end

    it "returns empty when no tours match" do
      get :index, params: { url: "/unknown" }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tour"]).to be_nil
    end

    it "returns 401 when no user" do
      allow(controller).to receive(:current_user).and_return(nil)

      get :index, params: { url: "/dashboard" }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/api/tours_controller_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write API base controller**

Create `app/controllers/onboard_on_rails/api/base_controller.rb`:
```ruby
module OnboardOnRails
  module Api
    class BaseController < ApplicationController
      skip_forgery_protection
      before_action :authenticate_user!

      private

      def current_user
        method_name = OnboardOnRails.configuration.current_user_method
        main_app_controller = request.env["action_controller.instance"]
        if main_app_controller&.respond_to?(method_name, true)
          main_app_controller.send(method_name)
        else
          send(method_name) if respond_to?(method_name, true)
        end
      end

      def authenticate_user!
        head :unauthorized unless current_user
      end
    end
  end
end
```

- [ ] **Step 4: Write API tours controller**

Create `app/controllers/onboard_on_rails/api/tours_controller.rb`:
```ruby
module OnboardOnRails
  module Api
    class ToursController < BaseController
      def index
        tour = TourMatcher.new(
          user: current_user,
          url: params[:url],
          session_id: params[:session_id]
        ).match

        if tour
          render json: {
            tour: serialize_tour(tour)
          }
        else
          render json: { tour: nil }
        end
      end

      private

      def serialize_tour(tour)
        {
          id: tour.id,
          name: tour.name,
          theme: tour.theme,
          style_overrides: tour.style_overrides,
          steps: tour.steps.map { |s| serialize_step(s) }
        }
      end

      def serialize_step(step)
        {
          id: step.id,
          position: step.position,
          title: step.title,
          body: step.body,
          selector: step.selector,
          placement: step.placement,
          url_pattern: step.url_pattern,
          style_overrides: step.style_overrides,
          action_type: step.action_type,
          action_value: step.action_value,
          wait_for_selector: step.wait_for_selector
        }
      end
    end
  end
end
```

- [ ] **Step 5: Run API tours tests**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/api/tours_controller_spec.rb
```

Expected: All pass.

- [ ] **Step 6: Write API completions controller tests**

Create `spec/controllers/onboard_on_rails/api/completions_controller_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Api::CompletionsController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:user) { User.create!(email: "test@test.com") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    let(:tour) { create(:tour) }
    let(:step) { create(:step, tour: tour) }

    it "creates a new completion" do
      post :create, params: {
        tour_id: tour.id,
        step_id: step.id,
        status: "in_progress",
        session_id: "abc123"
      }, format: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["completion"]["tour_id"]).to eq(tour.id)
    end

    it "updates existing completion for same user + tour" do
      existing = create(:completion, tour: tour, user_id: user.id, status: "in_progress")

      post :create, params: {
        tour_id: tour.id,
        step_id: step.id,
        status: "completed",
        session_id: "abc123"
      }, format: :json

      expect(response).to have_http_status(:ok)
      expect(existing.reload.status).to eq("completed")
    end
  end
end
```

- [ ] **Step 7: Write API completions controller**

Create `app/controllers/onboard_on_rails/api/completions_controller.rb`:
```ruby
module OnboardOnRails
  module Api
    class CompletionsController < BaseController
      def create
        completion = Completion.find_or_initialize_by(
          tour_id: params[:tour_id],
          user_id: current_user.id
        )

        was_new = completion.new_record?
        completion.step_id = params[:step_id]
        completion.status = params[:status]
        completion.session_id = params[:session_id]
        completion.started_at ||= Time.current
        completion.completed_at = Time.current if params[:status] == "completed"

        if completion.save
          status_code = was_new ? :created : :ok
          render json: { completion: { id: completion.id, tour_id: completion.tour_id, status: completion.status } }, status: status_code
        else
          render json: { errors: completion.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
```

- [ ] **Step 8: Run completions tests**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/api/completions_controller_spec.rb
```

Expected: All pass.

- [ ] **Step 9: Write API events controller tests**

Create `spec/controllers/onboard_on_rails/api/events_controller_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Api::EventsController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:user) { User.create!(email: "test@test.com") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    it "creates an event" do
      post :create, params: {
        name: "first_project_created",
        payload: { project_id: 42 }
      }, format: :json

      expect(response).to have_http_status(:created)
      expect(OnboardOnRails::Event.last.name).to eq("first_project_created")
      expect(OnboardOnRails::Event.last.user_id).to eq(user.id)
    end
  end
end
```

- [ ] **Step 10: Write API events controller**

Create `app/controllers/onboard_on_rails/api/events_controller.rb`:
```ruby
module OnboardOnRails
  module Api
    class EventsController < BaseController
      def create
        event = Event.new(
          user_id: current_user.id,
          name: params[:name],
          payload: params[:payload] || {}
        )

        if event.save
          render json: { event: { id: event.id, name: event.name } }, status: :created
        else
          render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
```

- [ ] **Step 11: Run all API tests**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/api/
```

Expected: All pass.

- [ ] **Step 12: Commit**

```bash
git add -A
git commit -m "feat: add API controllers for tours, completions, and events"
```

---

## Task 12: Meta Tags Helper

**Files:**
- Create: `app/helpers/onboard_on_rails/meta_tags_helper.rb`

- [ ] **Step 1: Write meta tags helper**

Create `app/helpers/onboard_on_rails/meta_tags_helper.rb`:
```ruby
module OnboardOnRails
  module MetaTagsHelper
    def onboard_on_rails_meta_tags
      user = send(OnboardOnRails.configuration.current_user_method)
      return "" unless user

      mount_path = OnboardOnRails::Engine.routes.find_script_name({})
      mount_path = "/onboard" if mount_path.blank?

      tag.meta(name: "onboard-on-rails-user-id", content: user.id) +
        tag.meta(name: "onboard-on-rails-mount-path", content: mount_path) +
        tag.meta(name: "csrf-token", content: form_authenticity_token)
    end
  end
end
```

Add to `lib/onboard_on_rails/engine.rb` inside the class:
```ruby
initializer "onboard_on_rails.helpers" do
  ActiveSupport.on_load(:action_view) do
    include OnboardOnRails::MetaTagsHelper
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add meta tags helper for client JS initialization"
```

---

## Task 13: Admin Base Controller & Layout

**Files:**
- Create: `app/controllers/onboard_on_rails/admin/base_controller.rb`
- Create: `app/views/layouts/onboard_on_rails/admin.html.erb`
- Create: `app/assets/stylesheets/onboard_on_rails/admin.css`
- Create: `app/assets/javascripts/onboard_on_rails/admin.js`

- [ ] **Step 1: Write admin base controller**

Create `app/controllers/onboard_on_rails/admin/base_controller.rb`:
```ruby
module OnboardOnRails
  module Admin
    class BaseController < ApplicationController
      layout "onboard_on_rails/admin"
      before_action :authorize_admin!

      private

      def authorize_admin!
        auth = OnboardOnRails.configuration.admin_auth
        unless auth.call(self)
          head :forbidden
        end
      end

      def current_user
        method_name = OnboardOnRails.configuration.current_user_method
        send(method_name) if respond_to?(method_name, true)
      end
      helper_method :current_user
    end
  end
end
```

- [ ] **Step 2: Write admin layout**

Create `app/views/layouts/onboard_on_rails/admin.html.erb`:
```erb
<!DOCTYPE html>
<html>
<head>
  <title>OnboardOnRails Admin</title>
  <%= stylesheet_link_tag "onboard_on_rails/admin", media: "all" %>
  <%= javascript_include_tag "onboard_on_rails/admin" %>
  <%= csrf_meta_tags %>
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <nav class="oor-admin-nav">
    <div class="oor-admin-nav__brand">
      <%= link_to "OnboardOnRails", onboard_on_rails.admin_root_path, class: "oor-admin-nav__logo" %>
    </div>
    <div class="oor-admin-nav__links">
      <%= link_to "Tours", onboard_on_rails.admin_tours_path, class: "oor-admin-nav__link" %>
    </div>
  </nav>

  <main class="oor-admin-main">
    <% if flash[:notice] %>
      <div class="oor-admin-flash oor-admin-flash--notice"><%= flash[:notice] %></div>
    <% end %>
    <% if flash[:alert] %>
      <div class="oor-admin-flash oor-admin-flash--alert"><%= flash[:alert] %></div>
    <% end %>

    <%= yield %>
  </main>
</body>
</html>
```

- [ ] **Step 3: Write admin CSS**

Create `app/assets/stylesheets/onboard_on_rails/admin.css`:
```css
/* OnboardOnRails Admin Panel */
:root {
  --oor-primary: #6c5ce7;
  --oor-primary-hover: #5a4bd1;
  --oor-bg: #f8f9fa;
  --oor-surface: #ffffff;
  --oor-border: #e2e8f0;
  --oor-text: #1a202c;
  --oor-text-muted: #718096;
  --oor-danger: #e53e3e;
  --oor-success: #38a169;
  --oor-warning: #d69e2e;
  --oor-radius: 8px;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  background: var(--oor-bg);
  color: var(--oor-text);
}

.oor-admin-nav {
  background: var(--oor-surface);
  border-bottom: 1px solid var(--oor-border);
  padding: 0 24px;
  height: 56px;
  display: flex;
  align-items: center;
  gap: 32px;
}

.oor-admin-nav__logo {
  font-weight: 700;
  font-size: 16px;
  color: var(--oor-primary);
  text-decoration: none;
}

.oor-admin-nav__link {
  color: var(--oor-text-muted);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
}

.oor-admin-nav__link:hover { color: var(--oor-text); }

.oor-admin-main {
  max-width: 1200px;
  margin: 0 auto;
  padding: 24px;
}

.oor-admin-flash {
  padding: 12px 16px;
  border-radius: var(--oor-radius);
  margin-bottom: 16px;
  font-size: 14px;
}

.oor-admin-flash--notice { background: #f0fff4; color: var(--oor-success); border: 1px solid #c6f6d5; }
.oor-admin-flash--alert { background: #fff5f5; color: var(--oor-danger); border: 1px solid #fed7d7; }

/* Page header */
.oor-page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.oor-page-header h1 {
  font-size: 24px;
  font-weight: 700;
  margin: 0;
}

/* Buttons */
.oor-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border-radius: var(--oor-radius);
  font-size: 14px;
  font-weight: 500;
  text-decoration: none;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}

.oor-btn--primary { background: var(--oor-primary); color: white; }
.oor-btn--primary:hover { background: var(--oor-primary-hover); }
.oor-btn--secondary { background: var(--oor-surface); color: var(--oor-text); border: 1px solid var(--oor-border); }
.oor-btn--secondary:hover { background: var(--oor-bg); }
.oor-btn--danger { background: var(--oor-danger); color: white; }
.oor-btn--sm { padding: 4px 10px; font-size: 12px; }

/* Table */
.oor-table {
  width: 100%;
  background: var(--oor-surface);
  border-radius: var(--oor-radius);
  border: 1px solid var(--oor-border);
  border-collapse: separate;
  border-spacing: 0;
  overflow: hidden;
}

.oor-table th {
  text-align: left;
  padding: 12px 16px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--oor-text-muted);
  background: var(--oor-bg);
  border-bottom: 1px solid var(--oor-border);
}

.oor-table td {
  padding: 12px 16px;
  font-size: 14px;
  border-bottom: 1px solid var(--oor-border);
}

.oor-table tr:last-child td { border-bottom: none; }

/* Badge */
.oor-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
}

.oor-badge--active { background: #f0fff4; color: var(--oor-success); }
.oor-badge--draft { background: #fefcbf; color: var(--oor-warning); }
.oor-badge--archived { background: #edf2f7; color: var(--oor-text-muted); }

/* Forms */
.oor-form-group {
  margin-bottom: 16px;
}

.oor-form-group label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  margin-bottom: 4px;
  color: var(--oor-text);
}

.oor-form-group input,
.oor-form-group select,
.oor-form-group textarea {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid var(--oor-border);
  border-radius: var(--oor-radius);
  font-size: 14px;
  font-family: inherit;
  background: var(--oor-surface);
  color: var(--oor-text);
}

.oor-form-group textarea { min-height: 80px; resize: vertical; }

.oor-form-group input:focus,
.oor-form-group select:focus,
.oor-form-group textarea:focus {
  outline: none;
  border-color: var(--oor-primary);
  box-shadow: 0 0 0 3px rgba(108, 92, 231, 0.1);
}

/* Two-panel layout */
.oor-panel-layout {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}

.oor-panel {
  background: var(--oor-surface);
  border: 1px solid var(--oor-border);
  border-radius: var(--oor-radius);
  padding: 20px;
}

.oor-panel__title {
  font-size: 14px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--oor-primary);
  margin: 0 0 16px 0;
}

/* Step list in tour editor */
.oor-step-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.oor-step-item {
  padding: 10px 12px;
  border: 1px solid var(--oor-border);
  border-radius: var(--oor-radius);
  margin-bottom: 8px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: var(--oor-surface);
  cursor: grab;
}

.oor-step-item:hover { border-color: var(--oor-primary); }

.oor-step-item__info { flex: 1; }
.oor-step-item__title { font-weight: 600; font-size: 14px; }
.oor-step-item__meta { font-size: 12px; color: var(--oor-text-muted); }

/* Placement selector */
.oor-placement-options {
  display: flex;
  gap: 4px;
}

.oor-placement-options label {
  padding: 4px 10px;
  border: 1px solid var(--oor-border);
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.15s;
}

.oor-placement-options input { display: none; }
.oor-placement-options input:checked + span {
  background: var(--oor-primary);
  color: white;
  border-color: var(--oor-primary);
}

/* Color picker */
.oor-color-input {
  display: flex;
  align-items: center;
  gap: 8px;
}

.oor-color-input input[type="color"] {
  width: 32px;
  height: 32px;
  border: 1px solid var(--oor-border);
  border-radius: 4px;
  padding: 2px;
  cursor: pointer;
}

.oor-color-input input[type="text"] {
  width: 100px;
}
```

- [ ] **Step 4: Write admin JS entry point**

Create `app/assets/javascripts/onboard_on_rails/admin.js`:
```javascript
//= require_tree ./admin
```

Create `app/assets/javascripts/onboard_on_rails/admin/placeholder.js`:
```javascript
// Stimulus controllers will be added in subsequent tasks
console.log("OnboardOnRails admin loaded");
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add admin base controller, layout, and CSS"
```

---

## Task 14: Admin Tours Controller & Views

**Files:**
- Create: `app/controllers/onboard_on_rails/admin/tours_controller.rb`
- Create: `app/views/onboard_on_rails/admin/tours/index.html.erb`
- Create: `app/views/onboard_on_rails/admin/tours/new.html.erb`
- Create: `app/views/onboard_on_rails/admin/tours/edit.html.erb`
- Create: `app/views/onboard_on_rails/admin/tours/_form.html.erb`
- Create: `app/views/onboard_on_rails/admin/tours/_tour.html.erb`
- Test: `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb`

- [ ] **Step 1: Write admin tours controller tests**

Create `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Admin::ToursController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  before do
    OnboardOnRails.configure do |config|
      config.admin_auth = ->(controller) { true }
    end
  end

  describe "GET #index" do
    it "returns a list of tours" do
      create(:tour, name: "Welcome")
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #new" do
    it "renders the new tour form" do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a tour" do
      post :create, params: { tour: { name: "New Tour", url_pattern: ["/dashboard/*"] } }
      expect(OnboardOnRails::Tour.count).to eq(1)
      expect(response).to redirect_to(admin_tour_path(OnboardOnRails::Tour.last))
    end
  end

  describe "GET #edit" do
    it "renders the edit form" do
      tour = create(:tour)
      get :edit, params: { id: tour.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    it "updates the tour" do
      tour = create(:tour, name: "Old")
      patch :update, params: { id: tour.id, tour: { name: "New" } }
      expect(tour.reload.name).to eq("New")
    end
  end

  describe "DELETE #destroy" do
    it "destroys the tour" do
      tour = create(:tour)
      delete :destroy, params: { id: tour.id }
      expect(OnboardOnRails::Tour.count).to eq(0)
    end
  end

  describe "authorization" do
    it "returns 403 when admin_auth fails" do
      OnboardOnRails.configure { |c| c.admin_auth = ->(ctrl) { false } }
      get :index
      expect(response).to have_http_status(:forbidden)
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write admin tours controller**

Create `app/controllers/onboard_on_rails/admin/tours_controller.rb`:
```ruby
module OnboardOnRails
  module Admin
    class ToursController < BaseController
      before_action :set_tour, only: [:show, :edit, :update, :destroy]

      def index
        @tours = Tour.order(updated_at: :desc)
        @tours = @tours.where(status: params[:status]) if params[:status].present?
      end

      def new
        @tour = Tour.new
      end

      def create
        @tour = Tour.new(tour_params)
        if @tour.save
          redirect_to admin_tour_path(@tour), notice: "Tour created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def show
        redirect_to edit_admin_tour_path(@tour)
      end

      def edit
      end

      def update
        if @tour.update(tour_params)
          redirect_to edit_admin_tour_path(@tour), notice: "Tour updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @tour.destroy
        redirect_to admin_tours_path, notice: "Tour deleted."
      end

      private

      def set_tour
        @tour = Tour.find(params[:id])
      end

      def tour_params
        params.require(:tour).permit(
          :name, :description, :status, :trigger_type, :trigger_event,
          :frequency, :theme, :priority, :schedule_start, :schedule_end,
          :ab_test_id, :ab_test_group,
          url_pattern: [], style_overrides: {}, segment_rules: {}
        )
      end
    end
  end
end
```

- [ ] **Step 4: Write tours index view**

Create `app/views/onboard_on_rails/admin/tours/index.html.erb`:
```erb
<div class="oor-page-header">
  <h1>Tours</h1>
  <%= link_to "New Tour", new_admin_tour_path, class: "oor-btn oor-btn--primary" %>
</div>

<div style="margin-bottom: 16px; display: flex; gap: 8px;">
  <%= link_to "All", admin_tours_path, class: "oor-btn oor-btn--sm #{params[:status].blank? ? 'oor-btn--primary' : 'oor-btn--secondary'}" %>
  <% %w[active draft archived].each do |status| %>
    <%= link_to status.capitalize, admin_tours_path(status: status), class: "oor-btn oor-btn--sm #{params[:status] == status ? 'oor-btn--primary' : 'oor-btn--secondary'}" %>
  <% end %>
</div>

<table class="oor-table">
  <thead>
    <tr>
      <th>Name</th>
      <th>Status</th>
      <th>Steps</th>
      <th>URL Pattern</th>
      <th>Trigger</th>
      <th>Priority</th>
      <th>Actions</th>
    </tr>
  </thead>
  <tbody>
    <% @tours.each do |tour| %>
      <%= render "tour", tour: tour %>
    <% end %>
    <% if @tours.empty? %>
      <tr>
        <td colspan="7" style="text-align: center; color: var(--oor-text-muted); padding: 32px;">
          No tours yet. Create your first tour to get started.
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

- [ ] **Step 5: Write tour row partial**

Create `app/views/onboard_on_rails/admin/tours/_tour.html.erb`:
```erb
<tr id="<%= dom_id(tour) %>">
  <td><%= link_to tour.name, edit_admin_tour_path(tour), style: "color: var(--oor-primary); text-decoration: none; font-weight: 500;" %></td>
  <td><span class="oor-badge oor-badge--<%= tour.status %>"><%= tour.status %></span></td>
  <td><%= tour.steps.size %></td>
  <td style="font-family: monospace; font-size: 12px; color: var(--oor-text-muted);"><%= Array(tour.url_pattern).join(", ") %></td>
  <td><%= tour.trigger_type %></td>
  <td><%= tour.priority %></td>
  <td>
    <%= link_to "Edit", edit_admin_tour_path(tour), class: "oor-btn oor-btn--secondary oor-btn--sm" %>
    <%= button_to "Delete", admin_tour_path(tour), method: :delete, class: "oor-btn oor-btn--danger oor-btn--sm", data: { turbo_confirm: "Delete this tour?" } %>
  </td>
</tr>
```

- [ ] **Step 6: Write new/edit tour views and form partial**

Create `app/views/onboard_on_rails/admin/tours/new.html.erb`:
```erb
<div class="oor-page-header">
  <h1>New Tour</h1>
</div>

<div class="oor-panel" style="max-width: 600px;">
  <%= render "form", tour: @tour %>
</div>
```

Create `app/views/onboard_on_rails/admin/tours/edit.html.erb`:
```erb
<div class="oor-page-header">
  <h1>Edit: <%= @tour.name %></h1>
  <div style="display: flex; gap: 8px;">
    <%= link_to "Stats", admin_tour_stats_path(@tour), class: "oor-btn oor-btn--secondary" %>
    <%= link_to "Back", admin_tours_path, class: "oor-btn oor-btn--secondary" %>
  </div>
</div>

<div class="oor-panel-layout">
  <div>
    <div class="oor-panel">
      <h3 class="oor-panel__title">Tour Settings</h3>
      <%= render "form", tour: @tour %>
    </div>
  </div>

  <div>
    <div class="oor-panel">
      <h3 class="oor-panel__title">Steps</h3>

      <div id="steps-list">
        <ol class="oor-step-list">
          <% @tour.steps.each do |step| %>
            <li class="oor-step-item" data-step-id="<%= step.id %>">
              <div class="oor-step-item__info">
                <div class="oor-step-item__title"><%= step.title %></div>
                <div class="oor-step-item__meta"><%= step.selector %> &middot; <%= step.placement %></div>
              </div>
              <div style="display: flex; gap: 4px;">
                <%= link_to "Edit", edit_admin_tour_step_path(@tour, step), class: "oor-btn oor-btn--secondary oor-btn--sm" %>
                <%= button_to "Delete", admin_tour_step_path(@tour, step), method: :delete, class: "oor-btn oor-btn--danger oor-btn--sm", data: { turbo_confirm: "Delete step?" } %>
              </div>
            </li>
          <% end %>
        </ol>
      </div>

      <%= link_to "Add Step", new_admin_tour_step_path(@tour), class: "oor-btn oor-btn--primary", style: "margin-top: 12px;" %>
    </div>
  </div>
</div>
```

Create `app/views/onboard_on_rails/admin/tours/_form.html.erb`:
```erb
<%= form_with(model: [:admin, tour], url: tour.persisted? ? admin_tour_path(tour) : admin_tours_path) do |f| %>
  <% if tour.errors.any? %>
    <div style="background: #fff5f5; border: 1px solid #fed7d7; padding: 12px; border-radius: var(--oor-radius); margin-bottom: 16px; color: var(--oor-danger); font-size: 13px;">
      <% tour.errors.full_messages.each do |msg| %>
        <div><%= msg %></div>
      <% end %>
    </div>
  <% end %>

  <div class="oor-form-group">
    <%= f.label :name %>
    <%= f.text_field :name, class: "oor-form-input" %>
  </div>

  <div class="oor-form-group">
    <%= f.label :description %>
    <%= f.text_area :description %>
  </div>

  <div class="oor-form-group">
    <%= f.label :status %>
    <%= f.select :status, OnboardOnRails::Tour::STATUSES.map { |s| [s.capitalize, s] } %>
  </div>

  <div class="oor-form-group">
    <%= f.label :trigger_type %>
    <%= f.select :trigger_type, OnboardOnRails::Tour::TRIGGER_TYPES.map { |t| [t.capitalize, t] } %>
  </div>

  <div class="oor-form-group">
    <%= f.label :trigger_event, "Trigger Event (for event-type triggers)" %>
    <%= f.text_field :trigger_event %>
  </div>

  <div class="oor-form-group">
    <%= f.label :url_pattern, "URL Patterns (comma-separated)" %>
    <%= f.text_field :url_pattern, value: Array(tour.url_pattern).join(", ") %>
  </div>

  <div class="oor-form-group">
    <%= f.label :frequency %>
    <%= f.select :frequency, OnboardOnRails::Tour::FREQUENCIES.map { |fr| [fr.titleize, fr] } %>
  </div>

  <div class="oor-form-group">
    <%= f.label :theme %>
    <%= f.select :theme, OnboardOnRails::Tour::THEMES.map { |t| [t.capitalize, t] } %>
  </div>

  <div class="oor-form-group">
    <%= f.label :priority %>
    <%= f.number_field :priority %>
  </div>

  <div class="oor-form-group">
    <%= f.label :schedule_start %>
    <%= f.datetime_local_field :schedule_start %>
  </div>

  <div class="oor-form-group">
    <%= f.label :schedule_end %>
    <%= f.datetime_local_field :schedule_end %>
  </div>

  <div class="oor-form-group">
    <%= f.label :ab_test_id, "A/B Test ID" %>
    <%= f.text_field :ab_test_id %>
  </div>

  <div class="oor-form-group">
    <%= f.label :ab_test_group, "A/B Test Group" %>
    <%= f.text_field :ab_test_group %>
  </div>

  <%= f.submit tour.persisted? ? "Update Tour" : "Create Tour", class: "oor-btn oor-btn--primary" %>
<% end %>
```

- [ ] **Step 7: Run admin tours tests**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb
```

Expected: All pass.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add admin tours controller and views (CRUD + list)"
```

---

## Task 15: Admin Steps Controller & Views

**Files:**
- Create: `app/controllers/onboard_on_rails/admin/steps_controller.rb`
- Create: `app/views/onboard_on_rails/admin/steps/new.html.erb`
- Create: `app/views/onboard_on_rails/admin/steps/edit.html.erb`
- Create: `app/views/onboard_on_rails/admin/steps/_form.html.erb`
- Create: `app/views/onboard_on_rails/admin/steps/_preview.html.erb`
- Test: `spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb`

- [ ] **Step 1: Write admin steps controller tests**

Create `spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Admin::StepsController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:tour) { create(:tour) }

  before do
    OnboardOnRails.configure do |config|
      config.admin_auth = ->(controller) { true }
    end
  end

  describe "GET #new" do
    it "renders the new step form" do
      get :new, params: { tour_id: tour.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a step" do
      post :create, params: {
        tour_id: tour.id,
        step: { title: "Hello", selector: "#main", placement: "bottom" }
      }
      expect(tour.steps.count).to eq(1)
    end
  end

  describe "GET #edit" do
    it "renders the step editor with preview" do
      step = create(:step, tour: tour)
      get :edit, params: { tour_id: tour.id, id: step.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    it "updates the step" do
      step = create(:step, tour: tour, title: "Old")
      patch :update, params: { tour_id: tour.id, id: step.id, step: { title: "New" } }
      expect(step.reload.title).to eq("New")
    end
  end

  describe "DELETE #destroy" do
    it "destroys the step" do
      step = create(:step, tour: tour)
      delete :destroy, params: { tour_id: tour.id, id: step.id }
      expect(tour.steps.count).to eq(0)
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write admin steps controller**

Create `app/controllers/onboard_on_rails/admin/steps_controller.rb`:
```ruby
module OnboardOnRails
  module Admin
    class StepsController < BaseController
      before_action :set_tour
      before_action :set_step, only: [:edit, :update, :destroy]

      def new
        @step = @tour.steps.build(position: @tour.steps.count + 1)
      end

      def create
        @step = @tour.steps.build(step_params)
        @step.position ||= @tour.steps.count

        if @step.save
          redirect_to edit_admin_tour_step_path(@tour, @step), notice: "Step created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @step.update(step_params)
          redirect_to edit_admin_tour_step_path(@tour, @step), notice: "Step updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @step.destroy
        redirect_to edit_admin_tour_path(@tour), notice: "Step deleted."
      end

      private

      def set_tour
        @tour = Tour.find(params[:tour_id])
      end

      def set_step
        @step = @tour.steps.find(params[:id])
      end

      def step_params
        params.require(:step).permit(
          :title, :body, :selector, :placement, :position,
          :url_pattern, :action_type, :action_value, :wait_for_selector,
          style_overrides: {}
        )
      end
    end
  end
end
```

- [ ] **Step 4: Write step editor views**

Create `app/views/onboard_on_rails/admin/steps/new.html.erb`:
```erb
<div class="oor-page-header">
  <h1>New Step — <%= @tour.name %></h1>
  <%= link_to "Back to Tour", edit_admin_tour_path(@tour), class: "oor-btn oor-btn--secondary" %>
</div>

<div class="oor-panel" style="max-width: 600px;">
  <%= render "form", step: @step, tour: @tour %>
</div>
```

Create `app/views/onboard_on_rails/admin/steps/edit.html.erb`:
```erb
<div class="oor-page-header">
  <h1>Edit Step — <%= @step.title %></h1>
  <%= link_to "Back to Tour", edit_admin_tour_path(@tour), class: "oor-btn oor-btn--secondary" %>
</div>

<div class="oor-panel-layout">
  <div class="oor-panel">
    <h3 class="oor-panel__title">Step Settings</h3>
    <%= render "form", step: @step, tour: @tour %>
  </div>

  <div class="oor-panel" data-controller="step-preview">
    <h3 class="oor-panel__title">Live Preview</h3>
    <%= render "preview", step: @step, tour: @tour %>
  </div>
</div>
```

Create `app/views/onboard_on_rails/admin/steps/_form.html.erb`:
```erb
<%= form_with(model: [:admin, tour, step], url: step.persisted? ? admin_tour_step_path(tour, step) : admin_tour_steps_path(tour), data: { controller: "step-preview", step_preview_target: "form" }) do |f| %>
  <% if step.errors.any? %>
    <div style="background: #fff5f5; border: 1px solid #fed7d7; padding: 12px; border-radius: var(--oor-radius); margin-bottom: 16px; color: var(--oor-danger); font-size: 13px;">
      <% step.errors.full_messages.each do |msg| %>
        <div><%= msg %></div>
      <% end %>
    </div>
  <% end %>

  <div class="oor-form-group">
    <%= f.label :title %>
    <%= f.text_field :title, data: { step_preview_target: "title", action: "input->step-preview#update" } %>
  </div>

  <div class="oor-form-group">
    <%= f.label :body %>
    <%= f.text_area :body, data: { step_preview_target: "body", action: "input->step-preview#update" } %>
  </div>

  <div class="oor-form-group">
    <%= f.label :selector, "CSS Selector" %>
    <div style="display: flex; gap: 8px;">
      <%= f.text_field :selector, style: "flex: 1;", data: { step_preview_target: "selector" } %>
      <%= link_to "Pick", selector_picker_path(tour_id: tour.id, step_id: step.id), class: "oor-btn oor-btn--primary", target: "_blank" %>
    </div>
  </div>

  <div class="oor-form-group">
    <%= f.label :placement %>
    <div class="oor-placement-options">
      <% OnboardOnRails::Step::PLACEMENTS.each do |p| %>
        <label>
          <%= f.radio_button :placement, p, data: { action: "change->step-preview#update" } %>
          <span class="oor-btn oor-btn--sm oor-btn--secondary"><%= p %></span>
        </label>
      <% end %>
    </div>
  </div>

  <div class="oor-form-group">
    <%= f.label :action_type %>
    <%= f.select :action_type, OnboardOnRails::Step::ACTION_TYPES.map { |a| [a.titleize, a] } %>
  </div>

  <div class="oor-form-group">
    <%= f.label :action_value, "Action Value (URL or event name)" %>
    <%= f.text_field :action_value %>
  </div>

  <div class="oor-form-group">
    <%= f.label :wait_for_selector, "Wait For Selector (optional)" %>
    <%= f.text_field :wait_for_selector %>
  </div>

  <div class="oor-form-group">
    <%= f.label :url_pattern, "URL Pattern (optional, if step is on different page)" %>
    <%= f.text_field :url_pattern %>
  </div>

  <h4 style="margin-top: 24px; color: var(--oor-primary); font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px;">Style Overrides</h4>

  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
    <div class="oor-form-group">
      <label>Background</label>
      <div class="oor-color-input">
        <input type="color" name="step[style_overrides][background]" value="<%= step.style_overrides.dig('background') || '#ffffff' %>" data-step-preview-target="bgColor" data-action="input->step-preview#update">
        <input type="text" value="<%= step.style_overrides.dig('background') || '#ffffff' %>" disabled>
      </div>
    </div>

    <div class="oor-form-group">
      <label>Text Color</label>
      <div class="oor-color-input">
        <input type="color" name="step[style_overrides][text_color]" value="<%= step.style_overrides.dig('text_color') || '#333333' %>" data-step-preview-target="textColor" data-action="input->step-preview#update">
        <input type="text" value="<%= step.style_overrides.dig('text_color') || '#333333' %>" disabled>
      </div>
    </div>

    <div class="oor-form-group">
      <label>Font Family</label>
      <select name="step[style_overrides][font_family]" data-step-preview-target="fontFamily" data-action="change->step-preview#update">
        <option value="inherit">Inherit</option>
        <option value="Inter, sans-serif" <%= 'selected' if step.style_overrides.dig('font_family') == 'Inter, sans-serif' %>>Inter</option>
        <option value="system-ui, sans-serif" <%= 'selected' if step.style_overrides.dig('font_family') == 'system-ui, sans-serif' %>>System UI</option>
        <option value="Georgia, serif" <%= 'selected' if step.style_overrides.dig('font_family') == 'Georgia, serif' %>>Georgia</option>
        <option value="monospace" <%= 'selected' if step.style_overrides.dig('font_family') == 'monospace' %>>Monospace</option>
      </select>
    </div>

    <div class="oor-form-group">
      <label>Font Size</label>
      <select name="step[style_overrides][font_size]" data-step-preview-target="fontSize" data-action="change->step-preview#update">
        <% %w[12px 13px 14px 15px 16px].each do |size| %>
          <option value="<%= size %>" <%= 'selected' if step.style_overrides.dig('font_size') == size %>><%= size %></option>
        <% end %>
      </select>
    </div>

    <div class="oor-form-group">
      <label>Border Radius</label>
      <select name="step[style_overrides][border_radius]" data-step-preview-target="borderRadius" data-action="change->step-preview#update">
        <% %w[0px 4px 8px 12px 16px].each do |r| %>
          <option value="<%= r %>" <%= 'selected' if step.style_overrides.dig('border_radius') == r %>><%= r %></option>
        <% end %>
      </select>
    </div>

    <div class="oor-form-group">
      <label>Button Color</label>
      <div class="oor-color-input">
        <input type="color" name="step[style_overrides][button_color]" value="<%= step.style_overrides.dig('button_color') || '#6c5ce7' %>" data-step-preview-target="buttonColor" data-action="input->step-preview#update">
        <input type="text" value="<%= step.style_overrides.dig('button_color') || '#6c5ce7' %>" disabled>
      </div>
    </div>
  </div>

  <div style="margin-top: 20px;">
    <%= f.submit step.persisted? ? "Update Step" : "Create Step", class: "oor-btn oor-btn--primary" %>
  </div>
<% end %>
```

Create `app/views/onboard_on_rails/admin/steps/_preview.html.erb`:
```erb
<div data-step-preview-target="previewContainer" style="min-height: 300px;">
  <!-- Simulated page -->
  <div style="background: #e8eaed; border-radius: 8px; position: relative; overflow: hidden; min-height: 280px;">
    <!-- Fake header -->
    <div style="background: #fff; padding: 10px 16px; display: flex; align-items: center; gap: 8px; border-bottom: 1px solid #ddd;">
      <div style="width: 24px; height: 24px; background: var(--oor-primary); border-radius: 4px;"></div>
      <div style="background: #ddd; height: 8px; width: 60px; border-radius: 2px;"></div>
    </div>

    <!-- Overlay -->
    <div style="position: absolute; inset: 0; background: rgba(0,0,0,0.4); z-index: 1;"></div>

    <!-- Target highlight -->
    <div data-step-preview-target="highlight" style="position: absolute; top: 4px; left: 10px; width: 36px; height: 32px; box-shadow: 0 0 0 3px var(--oor-primary); border-radius: 4px; z-index: 2; background: #fff;"></div>

    <!-- Tooltip preview -->
    <div data-step-preview-target="tooltip" style="position: absolute; top: 44px; left: 10px; z-index: 3;">
      <div style="width: 0; height: 0; border-left: 8px solid transparent; border-right: 8px solid transparent; border-bottom: 8px solid white; margin-left: 12px;"></div>
      <div data-step-preview-target="tooltipBody" style="background: white; border-radius: 8px; padding: 16px; width: 280px; box-shadow: 0 8px 30px rgba(0,0,0,0.2);">
        <div data-step-preview-target="previewTitle" style="font-size: 14px; font-weight: 600; color: #333; margin-bottom: 6px;">
          <%= step.title.presence || "Step Title" %>
        </div>
        <div data-step-preview-target="previewBody" style="font-size: 13px; color: #666; line-height: 1.4; margin-bottom: 14px;">
          <%= step.body.presence || "Step description goes here..." %>
        </div>
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div style="display: flex; gap: 4px;">
            <div style="width: 8px; height: 8px; background: var(--oor-primary); border-radius: 50%;"></div>
            <div style="width: 8px; height: 8px; background: #ddd; border-radius: 50%;"></div>
            <div style="width: 8px; height: 8px; background: #ddd; border-radius: 50%;"></div>
          </div>
          <div style="display: flex; gap: 6px;">
            <span style="color: #888; font-size: 12px; padding: 4px 8px;">Skip</span>
            <span data-step-preview-target="previewButton" style="background: var(--oor-primary); color: white; font-size: 12px; padding: 4px 14px; border-radius: 4px;">Next</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Fake content -->
    <div style="padding: 16px;">
      <div style="background: #fff; border-radius: 6px; padding: 12px;">
        <div style="background: #ddd; height: 8px; width: 40%; border-radius: 2px; margin-bottom: 6px;"></div>
        <div style="background: #eee; height: 6px; width: 80%; border-radius: 2px;"></div>
      </div>
    </div>
  </div>

  <div style="color: var(--oor-text-muted); font-size: 12px; margin-top: 8px; text-align: center;">
    Preview updates as you change settings
  </div>
</div>
```

- [ ] **Step 5: Run admin steps tests**

```bash
bundle exec rspec spec/controllers/onboard_on_rails/admin/steps_controller_spec.rb
```

Expected: All pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add admin steps controller and views with live preview"
```

---

## Task 16: Step Preview Stimulus Controller

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/admin/step_preview_controller.js`

- [ ] **Step 1: Write the Stimulus controller**

Create `app/assets/javascripts/onboard_on_rails/admin/step_preview_controller.js`:
```javascript
(() => {
  const application = window.Stimulus || (window.Stimulus = Stimulus.start());

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
        if (this.hasBgColorTarget) {
          this.tooltipBodyTarget.style.background = this.bgColorTarget.value;
        }
        if (this.hasTextColorTarget) {
          this.previewTitleTarget.style.color = this.textColorTarget.value;
          this.previewBodyTarget.style.color = this.textColorTarget.value;
        }
        if (this.hasFontFamilyTarget) {
          this.tooltipBodyTarget.style.fontFamily = this.fontFamilyTarget.value;
        }
        if (this.hasFontSizeTarget) {
          this.previewBodyTarget.style.fontSize = this.fontSizeTarget.value;
        }
        if (this.hasBorderRadiusTarget) {
          this.tooltipBodyTarget.style.borderRadius = this.borderRadiusTarget.value;
        }
      }

      if (this.hasButtonColorTarget && this.hasPreviewButtonTarget) {
        this.previewButtonTarget.style.background = this.buttonColorTarget.value;
      }
    }
  });
})();
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add Stimulus step preview controller for live style updates"
```

---

## Task 17: Segment Rules Stimulus Controller

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/admin/segment_rules_controller.js`

- [ ] **Step 1: Write segment rules controller**

Create `app/assets/javascripts/onboard_on_rails/admin/segment_rules_controller.js`:
```javascript
(() => {
  const application = window.Stimulus || (window.Stimulus = Stimulus.start());

  application.register("segment-rules", class extends Stimulus.Controller {
    static targets = ["container", "template", "output", "logic"];

    connect() {
      this.loadExisting();
    }

    loadExisting() {
      const data = JSON.parse(this.outputTarget.value || "{}");
      if (data.conditions) {
        data.conditions.forEach(c => this.addConditionRow(c));
      }
      if (data.logic && this.hasLogicTarget) {
        this.logicTarget.value = data.logic;
      }
    }

    add() {
      this.addConditionRow({ attribute: "", operator: "eq", value: "" });
    }

    addConditionRow(condition) {
      const row = document.createElement("div");
      row.className = "oor-segment-row";
      row.style.cssText = "display: flex; gap: 8px; margin-bottom: 8px; align-items: center;";
      row.innerHTML = `
        <input type="text" placeholder="attribute" value="${condition.attribute}" class="oor-segment-attr" style="flex:1; padding: 6px 8px; border: 1px solid var(--oor-border); border-radius: 4px; font-size: 13px;">
        <select class="oor-segment-op" style="padding: 6px 8px; border: 1px solid var(--oor-border); border-radius: 4px; font-size: 13px;">
          <option value="eq" ${condition.operator === "eq" ? "selected" : ""}>equals</option>
          <option value="not_eq" ${condition.operator === "not_eq" ? "selected" : ""}>not equals</option>
          <option value="in" ${condition.operator === "in" ? "selected" : ""}>in</option>
          <option value="gt" ${condition.operator === "gt" ? "selected" : ""}>greater than</option>
          <option value="lt" ${condition.operator === "lt" ? "selected" : ""}>less than</option>
        </select>
        <input type="text" placeholder="value" value="${Array.isArray(condition.value) ? condition.value.join(", ") : condition.value}" class="oor-segment-val" style="flex:1; padding: 6px 8px; border: 1px solid var(--oor-border); border-radius: 4px; font-size: 13px;">
        <button type="button" data-action="click->segment-rules#removeRow" style="background: none; border: none; color: var(--oor-danger); cursor: pointer; font-size: 16px;">&times;</button>
      `;

      row.querySelectorAll("input, select").forEach(el => {
        el.addEventListener("change", () => this.serialize());
      });

      this.containerTarget.appendChild(row);
      this.serialize();
    }

    removeRow(event) {
      event.target.closest(".oor-segment-row").remove();
      this.serialize();
    }

    serialize() {
      const rows = this.containerTarget.querySelectorAll(".oor-segment-row");
      const conditions = Array.from(rows).map(row => {
        const op = row.querySelector(".oor-segment-op").value;
        let value = row.querySelector(".oor-segment-val").value;
        if (op === "in") {
          value = value.split(",").map(v => v.trim());
        }
        return {
          attribute: row.querySelector(".oor-segment-attr").value,
          operator: op,
          value: value
        };
      });

      const logic = this.hasLogicTarget ? this.logicTarget.value : "and";

      this.outputTarget.value = JSON.stringify({ conditions, logic });
    }
  });
})();
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add Stimulus segment rules controller for visual rule builder"
```

---

## Task 18: Client-Side JS — API Client & Theme Engine

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/client.js`
- Create: `app/assets/javascripts/onboard_on_rails/client/api_client.js`
- Create: `app/assets/javascripts/onboard_on_rails/client/theme_engine.js`

- [ ] **Step 1: Write API client**

Create `app/assets/javascripts/onboard_on_rails/client/api_client.js`:
```javascript
window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.ApiClient = {
  getMountPath() {
    const meta = document.querySelector('meta[name="onboard-on-rails-mount-path"]');
    return meta ? meta.content : "/onboard";
  },

  getCsrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : "";
  },

  getUserId() {
    const meta = document.querySelector('meta[name="onboard-on-rails-user-id"]');
    return meta ? meta.content : null;
  },

  async fetchTours(url, sessionId) {
    if (!this.getUserId()) return null;

    const mountPath = this.getMountPath();
    const params = new URLSearchParams({ url });
    if (sessionId) params.append("session_id", sessionId);

    const response = await fetch(`${mountPath}/api/tours?${params}`, {
      headers: { "Accept": "application/json" }
    });

    if (!response.ok) return null;
    const data = await response.json();
    return data.tour;
  },

  async updateCompletion(tourId, stepId, status, sessionId) {
    const mountPath = this.getMountPath();

    const response = await fetch(`${mountPath}/api/completions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCsrfToken()
      },
      body: JSON.stringify({
        tour_id: tourId,
        step_id: stepId,
        status: status,
        session_id: sessionId
      })
    });

    return response.ok;
  },

  async trackEvent(name, payload) {
    const mountPath = this.getMountPath();

    const response = await fetch(`${mountPath}/api/events`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCsrfToken()
      },
      body: JSON.stringify({ name, payload: payload || {} })
    });

    return response.ok;
  }
};
```

- [ ] **Step 2: Write theme engine**

Create `app/assets/javascripts/onboard_on_rails/client/theme_engine.js`:
```javascript
window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.ThemeEngine = {
  applyTheme(container, theme, tourOverrides, stepOverrides) {
    container.className = "oor-tour-step";
    container.classList.add(`oor-theme-${theme}`);

    const overrides = Object.assign({}, tourOverrides || {}, stepOverrides || {});

    if (overrides.background) container.style.setProperty("--oor-step-bg", overrides.background);
    if (overrides.text_color) container.style.setProperty("--oor-step-text", overrides.text_color);
    if (overrides.font_family) container.style.setProperty("--oor-step-font", overrides.font_family);
    if (overrides.font_size) container.style.setProperty("--oor-step-font-size", overrides.font_size);
    if (overrides.border_radius) container.style.setProperty("--oor-step-radius", overrides.border_radius);
    if (overrides.button_color) container.style.setProperty("--oor-step-btn-bg", overrides.button_color);
    if (overrides.max_width) container.style.setProperty("--oor-step-max-width", overrides.max_width);
  }
};
```

- [ ] **Step 3: Write client entry point**

Create `app/assets/javascripts/onboard_on_rails/client.js`:
```javascript
//= require_tree ./client
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add client-side API client and theme engine"
```

---

## Task 19: Client-Side JS — Positioning Engine

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/client/positioning_engine.js`

- [ ] **Step 1: Write positioning engine**

Create `app/assets/javascripts/onboard_on_rails/client/positioning_engine.js`:
```javascript
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

    const needed = {
      top: tooltipRect.height,
      bottom: tooltipRect.height,
      left: tooltipRect.width,
      right: tooltipRect.width
    };

    if (space[preferred] >= needed[preferred]) return preferred;

    const opposite = { top: "bottom", bottom: "top", left: "right", right: "left" };
    if (space[opposite[preferred]] >= needed[opposite[preferred]]) return opposite[preferred];

    return Object.entries(space).sort((a, b) => b[1] - a[1])[0][0];
  },

  getClipPath(targetEl) {
    const rect = targetEl.getBoundingClientRect();
    const pad = 4;
    const x = rect.left - pad;
    const y = rect.top - pad;
    const w = rect.width + pad * 2;
    const h = rect.height + pad * 2;
    const r = 4;

    return `polygon(
      0% 0%, 100% 0%, 100% 100%, 0% 100%, 0% 0%,
      ${x}px ${y + r}px,
      ${x + r}px ${y}px,
      ${x + w - r}px ${y}px,
      ${x + w}px ${y + r}px,
      ${x + w}px ${y + h - r}px,
      ${x + w - r}px ${y + h}px,
      ${x + r}px ${y + h}px,
      ${x}px ${y + h - r}px,
      ${x}px ${y + r}px
    )`;
  },

  scrollIntoView(targetEl) {
    const rect = targetEl.getBoundingClientRect();
    const isVisible = rect.top >= 0 && rect.bottom <= window.innerHeight;
    if (!isVisible) {
      targetEl.scrollIntoView({ behavior: "smooth", block: "center" });
    }
  }
};
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add client-side positioning engine with fallback placement"
```

---

## Task 20: Client-Side JS — TourRenderer

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/client/tour_renderer.js`

- [ ] **Step 1: Write tour renderer**

Create `app/assets/javascripts/onboard_on_rails/client/tour_renderer.js`:
```javascript
window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.TourRenderer = {
  overlay: null,
  tooltip: null,
  resizeHandler: null,

  show(tour, stepIndex, callbacks) {
    this.cleanup();

    const step = tour.steps[stepIndex];
    if (!step) return;

    const targetEl = step.placement === "center" ? null : document.querySelector(step.selector);
    if (!targetEl && step.placement !== "center") return;

    this.createOverlay(targetEl);
    this.createTooltip(tour, step, stepIndex, tour.steps.length, targetEl, callbacks);

    if (targetEl) {
      OnboardOnRails.PositioningEngine.scrollIntoView(targetEl);
    }

    this.resizeHandler = () => {
      if (targetEl) {
        this.overlay.style.clipPath = OnboardOnRails.PositioningEngine.getClipPath(targetEl);
        OnboardOnRails.PositioningEngine.position(this.tooltip, targetEl, step.placement);
      }
    };
    window.addEventListener("resize", this.resizeHandler);
    window.addEventListener("scroll", this.resizeHandler);
  },

  createOverlay(targetEl) {
    this.overlay = document.createElement("div");
    this.overlay.className = "oor-overlay";
    if (targetEl) {
      this.overlay.style.clipPath = OnboardOnRails.PositioningEngine.getClipPath(targetEl);
    }
    document.body.appendChild(this.overlay);
  },

  createTooltip(tour, step, stepIndex, totalSteps, targetEl, callbacks) {
    this.tooltip = document.createElement("div");
    OnboardOnRails.ThemeEngine.applyTheme(this.tooltip, tour.theme, tour.style_overrides, step.style_overrides);

    const isFirst = stepIndex === 0;
    const isLast = stepIndex === totalSteps - 1;

    this.tooltip.innerHTML = `
      <div class="oor-step-content">
        <div class="oor-step-title">${this.escapeHtml(step.title)}</div>
        <div class="oor-step-body">${step.body}</div>
      </div>
      <div class="oor-step-footer">
        <div class="oor-step-dots">
          ${tour.steps.map((_, i) => `<span class="oor-dot ${i === stepIndex ? 'oor-dot--active' : ''}"></span>`).join("")}
        </div>
        <div class="oor-step-actions">
          <button class="oor-btn-skip" data-action="dismiss">Skip</button>
          ${!isFirst ? '<button class="oor-btn-prev" data-action="prev">Back</button>' : ''}
          <button class="oor-btn-next" data-action="${isLast ? 'complete' : 'next'}">${isLast ? 'Done' : 'Next'}</button>
        </div>
      </div>
    `;

    this.tooltip.addEventListener("click", (e) => {
      const action = e.target.dataset.action;
      if (action && callbacks[action]) callbacks[action]();
    });

    document.body.appendChild(this.tooltip);

    if (targetEl) {
      OnboardOnRails.PositioningEngine.position(this.tooltip, targetEl, step.placement);
    } else {
      this.tooltip.style.position = "fixed";
      this.tooltip.style.top = "50%";
      this.tooltip.style.left = "50%";
      this.tooltip.style.transform = "translate(-50%, -50%)";
      this.tooltip.style.zIndex = "10001";
    }
  },

  cleanup() {
    if (this.overlay) { this.overlay.remove(); this.overlay = null; }
    if (this.tooltip) { this.tooltip.remove(); this.tooltip = null; }
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler);
      window.removeEventListener("scroll", this.resizeHandler);
      this.resizeHandler = null;
    }
  },

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
};
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add TourRenderer — overlay, tooltip, step navigation"
```

---

## Task 21: Client-Side JS — DOMObserver

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/client/dom_observer.js`

- [ ] **Step 1: Write DOM observer**

Create `app/assets/javascripts/onboard_on_rails/client/dom_observer.js`:
```javascript
window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.DOMObserver = {
  mutationObserver: null,
  waitCallbacks: [],

  start(onNavigate) {
    document.addEventListener("turbo:load", () => onNavigate());
    document.addEventListener("turbo:before-render", () => {
      OnboardOnRails.TourRenderer.cleanup();
    });

    this.mutationObserver = new MutationObserver((mutations) => {
      this.checkWaitCallbacks();
    });

    this.mutationObserver.observe(document.body, {
      childList: true,
      subtree: true
    });
  },

  stop() {
    if (this.mutationObserver) {
      this.mutationObserver.disconnect();
      this.mutationObserver = null;
    }
    this.waitCallbacks = [];
  },

  waitForSelector(selector, callback, timeoutMs) {
    const el = document.querySelector(selector);
    if (el) {
      callback(el);
      return;
    }

    const entry = { selector, callback, added: Date.now(), timeoutMs: timeoutMs || 10000 };
    this.waitCallbacks.push(entry);
  },

  checkWaitCallbacks() {
    const now = Date.now();
    this.waitCallbacks = this.waitCallbacks.filter(entry => {
      if (now - entry.added > entry.timeoutMs) return false;

      const el = document.querySelector(entry.selector);
      if (el) {
        entry.callback(el);
        return false;
      }
      return true;
    });
  }
};
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add DOMObserver for Turbo navigation and MutationObserver"
```

---

## Task 22: Client-Side JS — TourManager (Entry Point)

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/client/tour_manager.js`

- [ ] **Step 1: Write tour manager**

Create `app/assets/javascripts/onboard_on_rails/client/tour_manager.js`:
```javascript
window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.TourManager = {
  currentTour: null,
  currentStepIndex: 0,
  sessionId: null,

  init() {
    if (!OnboardOnRails.ApiClient.getUserId()) return;

    this.sessionId = this.getOrCreateSessionId();
    this.loadTour();

    OnboardOnRails.DOMObserver.start(() => this.loadTour());
  },

  async loadTour() {
    OnboardOnRails.TourRenderer.cleanup();

    const url = window.location.pathname;
    const tour = await OnboardOnRails.ApiClient.fetchTours(url, this.sessionId);

    if (!tour) {
      this.currentTour = null;
      return;
    }

    this.currentTour = tour;
    this.currentStepIndex = 0;
    this.showStep();
  },

  showStep() {
    if (!this.currentTour) return;

    const step = this.currentTour.steps[this.currentStepIndex];
    if (!step) return;

    if (step.url_pattern && !this.matchesCurrentUrl(step.url_pattern)) {
      window.location.href = step.url_pattern;
      return;
    }

    const showFn = () => {
      OnboardOnRails.TourRenderer.show(this.currentTour, this.currentStepIndex, {
        next: () => this.next(),
        prev: () => this.prev(),
        dismiss: () => this.dismiss(),
        complete: () => this.complete()
      });
    };

    if (step.wait_for_selector) {
      OnboardOnRails.DOMObserver.waitForSelector(step.wait_for_selector, showFn);
    } else {
      const targetEl = step.placement === "center" ? true : document.querySelector(step.selector);
      if (targetEl) {
        showFn();
      } else {
        OnboardOnRails.DOMObserver.waitForSelector(step.selector, showFn);
      }
    }
  },

  async next() {
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(
      this.currentTour.id, step.id, "in_progress", this.sessionId
    );

    if (step.action_type === "redirect" && step.action_value) {
      window.location.href = step.action_value;
      return;
    }

    if (step.action_type === "custom_event" && step.action_value) {
      await OnboardOnRails.ApiClient.trackEvent(step.action_value);
    }

    this.currentStepIndex++;
    if (this.currentStepIndex < this.currentTour.steps.length) {
      this.showStep();
    } else {
      this.complete();
    }
  },

  prev() {
    if (this.currentStepIndex > 0) {
      this.currentStepIndex--;
      this.showStep();
    }
  },

  async dismiss() {
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(
      this.currentTour.id, step.id, "dismissed", this.sessionId
    );
    OnboardOnRails.TourRenderer.cleanup();
    this.currentTour = null;
  },

  async complete() {
    const step = this.currentTour.steps[this.currentStepIndex];
    await OnboardOnRails.ApiClient.updateCompletion(
      this.currentTour.id, step.id, "completed", this.sessionId
    );
    OnboardOnRails.TourRenderer.cleanup();
    this.currentTour = null;
  },

  matchesCurrentUrl(pattern) {
    return window.location.pathname === pattern ||
      window.location.pathname.startsWith(pattern.replace("*", ""));
  },

  getOrCreateSessionId() {
    let id = sessionStorage.getItem("oor_session_id");
    if (!id) {
      id = Math.random().toString(36).substring(2) + Date.now().toString(36);
      sessionStorage.setItem("oor_session_id", id);
    }
    return id;
  }
};

// Public API
OnboardOnRails.trackEvent = function(name, payload) {
  return OnboardOnRails.ApiClient.trackEvent(name, payload);
};

// Auto-init on DOMContentLoaded
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", () => OnboardOnRails.TourManager.init());
} else {
  OnboardOnRails.TourManager.init();
}
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add TourManager — entry point, step navigation, auto-init"
```

---

## Task 23: Client CSS — Tour Overlay & Theme Presets

**Files:**
- Create: `app/assets/stylesheets/onboard_on_rails/client.css`

- [ ] **Step 1: Write client CSS**

Create `app/assets/stylesheets/onboard_on_rails/client.css`:
```css
/* OnboardOnRails Client — Tour Overlay & Themes */

.oor-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 10000;
  pointer-events: auto;
}

/* Base step styles */
.oor-tour-step {
  --oor-step-bg: #ffffff;
  --oor-step-text: #333333;
  --oor-step-font: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  --oor-step-font-size: 14px;
  --oor-step-radius: 8px;
  --oor-step-btn-bg: #6c5ce7;
  --oor-step-max-width: 320px;

  position: absolute;
  z-index: 10001;
  max-width: var(--oor-step-max-width);
  background: var(--oor-step-bg);
  border-radius: var(--oor-step-radius);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.15);
  font-family: var(--oor-step-font);
  color: var(--oor-step-text);
  animation: oor-fade-in 0.2s ease;
}

@keyframes oor-fade-in {
  from { opacity: 0; transform: translateY(4px); }
  to { opacity: 1; transform: translateY(0); }
}

.oor-step-content {
  padding: 16px 16px 12px;
}

.oor-step-title {
  font-size: calc(var(--oor-step-font-size) + 1px);
  font-weight: 600;
  margin-bottom: 6px;
}

.oor-step-body {
  font-size: var(--oor-step-font-size);
  line-height: 1.5;
  color: color-mix(in srgb, var(--oor-step-text) 70%, transparent);
}

.oor-step-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 16px 12px;
}

.oor-step-dots {
  display: flex;
  gap: 4px;
}

.oor-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #ddd;
}

.oor-dot--active {
  background: var(--oor-step-btn-bg);
}

.oor-step-actions {
  display: flex;
  gap: 6px;
  align-items: center;
}

.oor-btn-skip {
  background: none;
  border: none;
  color: #888;
  font-size: 12px;
  cursor: pointer;
  padding: 4px 8px;
}

.oor-btn-skip:hover { color: #555; }

.oor-btn-prev {
  background: none;
  border: 1px solid #ddd;
  border-radius: 4px;
  color: var(--oor-step-text);
  font-size: 12px;
  cursor: pointer;
  padding: 4px 12px;
}

.oor-btn-prev:hover { background: #f5f5f5; }

.oor-btn-next {
  background: var(--oor-step-btn-bg);
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  padding: 4px 14px;
  font-weight: 500;
}

.oor-btn-next:hover { filter: brightness(0.9); }

/* Theme: Tooltip (default) */
.oor-theme-tooltip {
  max-width: var(--oor-step-max-width);
}

/* Theme: Modal */
.oor-theme-modal {
  position: fixed !important;
  top: 50% !important;
  left: 50% !important;
  transform: translate(-50%, -50%) !important;
  max-width: 480px;
  width: 90vw;
  --oor-step-max-width: 480px;
}

/* Theme: Banner */
.oor-theme-banner {
  position: fixed !important;
  bottom: 0 !important;
  left: 0 !important;
  right: 0 !important;
  top: auto !important;
  max-width: none;
  border-radius: 0;
  transform: none !important;
  padding: 4px 0;
}

.oor-theme-banner .oor-step-content,
.oor-theme-banner .oor-step-footer {
  max-width: 800px;
  margin: 0 auto;
}

/* Theme: Slideout */
.oor-theme-slideout {
  position: fixed !important;
  top: 0 !important;
  right: 0 !important;
  left: auto !important;
  bottom: 0 !important;
  max-width: 360px;
  width: 360px;
  border-radius: 0;
  transform: none !important;
  display: flex;
  flex-direction: column;
  justify-content: center;
  box-shadow: -4px 0 20px rgba(0, 0, 0, 0.1);
}
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add client CSS — overlay, tooltip, modal, banner, slideout themes"
```

---

## Task 24: Selector Picker (Visual Element Picker)

**Files:**
- Create: `app/controllers/onboard_on_rails/selector_picker_controller.rb`
- Create: `app/views/onboard_on_rails/selector_picker/show.html.erb`
- Create: `app/assets/javascripts/onboard_on_rails/client/selector_generator.js`

- [ ] **Step 1: Write selector picker controller**

Create `app/controllers/onboard_on_rails/selector_picker_controller.rb`:
```ruby
module OnboardOnRails
  class SelectorPickerController < Admin::BaseController
    def show
      @tour = Tour.find(params[:tour_id])
      @step = @tour.steps.find(params[:step_id]) if params[:step_id].present?
      @target_url = params[:url] || Array(@tour.url_pattern).first || "/"

      render layout: false
    end
  end
end
```

- [ ] **Step 2: Write selector generator JS**

Create `app/assets/javascripts/onboard_on_rails/client/selector_generator.js`:
```javascript
window.OnboardOnRails = window.OnboardOnRails || {};

OnboardOnRails.SelectorGenerator = {
  generate(element) {
    if (element.id) return `#${element.id}`;

    const unique = this.findUniqueClass(element);
    if (unique) return unique;

    return this.buildPath(element);
  },

  findUniqueClass(element) {
    for (const cls of element.classList) {
      if (cls.startsWith("js-") || cls.startsWith("oor-")) continue;
      const matches = document.querySelectorAll(`.${CSS.escape(cls)}`);
      if (matches.length === 1) return `.${cls}`;
    }
    return null;
  },

  buildPath(element) {
    const parts = [];
    let current = element;

    while (current && current !== document.body) {
      let selector = current.tagName.toLowerCase();

      if (current.id) {
        parts.unshift(`#${current.id}`);
        break;
      }

      const parent = current.parentElement;
      if (parent) {
        const siblings = Array.from(parent.children).filter(c => c.tagName === current.tagName);
        if (siblings.length > 1) {
          const index = siblings.indexOf(current) + 1;
          selector += `:nth-of-type(${index})`;
        }
      }

      parts.unshift(selector);
      current = parent;
    }

    return parts.join(" > ");
  }
};
```

- [ ] **Step 3: Write selector picker view**

Create `app/views/onboard_on_rails/selector_picker/show.html.erb`:
```erb
<!DOCTYPE html>
<html>
<head>
  <title>Select Element</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; }

    .oor-picker-toolbar {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      height: 48px;
      background: #1a1a2e;
      display: flex;
      align-items: center;
      padding: 0 16px;
      gap: 12px;
      z-index: 100000;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }

    .oor-picker-toolbar__label {
      color: #888;
      font-size: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }

    .oor-picker-toolbar__selector {
      flex: 1;
      background: #16213e;
      border: 1px solid #333;
      border-radius: 4px;
      padding: 6px 10px;
      color: #e0e0e0;
      font-family: monospace;
      font-size: 13px;
    }

    .oor-picker-toolbar__btn {
      padding: 6px 16px;
      border: none;
      border-radius: 4px;
      font-size: 13px;
      cursor: pointer;
      font-weight: 500;
    }

    .oor-picker-toolbar__btn--confirm {
      background: #6c5ce7;
      color: white;
    }

    .oor-picker-toolbar__btn--cancel {
      background: #333;
      color: #ccc;
    }

    .oor-picker-iframe {
      position: fixed;
      top: 48px;
      left: 0;
      right: 0;
      bottom: 0;
      border: none;
      width: 100%;
      height: calc(100vh - 48px);
    }
  </style>
</head>
<body>
  <div class="oor-picker-toolbar">
    <span class="oor-picker-toolbar__label">Selector:</span>
    <input type="text" class="oor-picker-toolbar__selector" id="selectorInput" placeholder="Click an element to select...">
    <button class="oor-picker-toolbar__btn oor-picker-toolbar__btn--confirm" id="confirmBtn">Confirm</button>
    <button class="oor-picker-toolbar__btn oor-picker-toolbar__btn--cancel" id="cancelBtn">Cancel</button>
  </div>

  <iframe class="oor-picker-iframe" id="targetFrame" src="<%= @target_url %>"></iframe>

  <%= javascript_include_tag "onboard_on_rails/client" %>
  <script>
    const iframe = document.getElementById("targetFrame");
    const selectorInput = document.getElementById("selectorInput");
    let highlightEl = null;

    iframe.addEventListener("load", () => {
      const doc = iframe.contentDocument;
      if (!doc) return;

      // Remove existing onboard scripts
      doc.querySelectorAll('script[src*="onboard_on_rails"]').forEach(s => s.remove());

      // Add hover highlight
      const style = doc.createElement("style");
      style.textContent = `
        .oor-picker-highlight {
          outline: 3px solid #6c5ce7 !important;
          outline-offset: 2px !important;
          cursor: crosshair !important;
        }
      `;
      doc.head.appendChild(style);

      doc.body.addEventListener("mouseover", (e) => {
        if (highlightEl) highlightEl.classList.remove("oor-picker-highlight");
        highlightEl = e.target;
        highlightEl.classList.add("oor-picker-highlight");
      });

      doc.body.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        const selector = OnboardOnRails.SelectorGenerator.generate(e.target);
        selectorInput.value = selector;
      }, true);
    });

    document.getElementById("confirmBtn").addEventListener("click", () => {
      const selector = selectorInput.value;
      if (window.opener) {
        window.opener.postMessage({ type: "oor-selector-picked", selector: selector }, "*");
      }
      window.close();
    });

    document.getElementById("cancelBtn").addEventListener("click", () => {
      window.close();
    });
  </script>
</body>
</html>
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add visual selector picker — iframe proxy, hover highlight, selector generation"
```

---

## Task 25: Stats Calculator & Admin Stats View

**Files:**
- Create: `app/services/onboard_on_rails/stats_calculator.rb`
- Create: `app/controllers/onboard_on_rails/admin/stats_controller.rb`
- Create: `app/views/onboard_on_rails/admin/stats/show.html.erb`
- Test: `spec/services/onboard_on_rails/stats_calculator_spec.rb`

- [ ] **Step 1: Write stats calculator tests**

Create `spec/services/onboard_on_rails/stats_calculator_spec.rb`:
```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::StatsCalculator do
  let(:tour) { create(:tour) }
  let!(:step1) { create(:step, tour: tour, position: 1) }
  let!(:step2) { create(:step, tour: tour, position: 2) }
  let!(:step3) { create(:step, tour: tour, position: 3) }

  describe "#summary" do
    it "calculates completion rate" do
      create(:completion, tour: tour, user_id: 1, status: "completed")
      create(:completion, tour: tour, user_id: 2, status: "completed")
      create(:completion, tour: tour, user_id: 3, status: "dismissed")
      create(:completion, tour: tour, user_id: 4, status: "in_progress")

      stats = described_class.new(tour).summary
      expect(stats[:total_started]).to eq(4)
      expect(stats[:completed]).to eq(2)
      expect(stats[:dismissed]).to eq(1)
      expect(stats[:completion_rate]).to eq(50.0)
    end

    it "handles zero completions" do
      stats = described_class.new(tour).summary
      expect(stats[:total_started]).to eq(0)
      expect(stats[:completion_rate]).to eq(0)
    end
  end

  describe "#drop_off_per_step" do
    it "returns step-level completion counts" do
      create(:completion, tour: tour, user_id: 1, step: step3, status: "completed")
      create(:completion, tour: tour, user_id: 2, step: step2, status: "dismissed")
      create(:completion, tour: tour, user_id: 3, step: step1, status: "dismissed")

      drop_off = described_class.new(tour).drop_off_per_step
      expect(drop_off.length).to eq(3)
      expect(drop_off[0][:step_id]).to eq(step1.id)
    end
  end
end
```

- [ ] **Step 2: Run to verify failures**

```bash
bundle exec rspec spec/services/onboard_on_rails/stats_calculator_spec.rb
```

Expected: FAIL.

- [ ] **Step 3: Write StatsCalculator**

Create `app/services/onboard_on_rails/stats_calculator.rb`:
```ruby
module OnboardOnRails
  class StatsCalculator
    def initialize(tour)
      @tour = tour
    end

    def summary
      completions = @tour.completions
      total = completions.count
      completed = completions.completed.count
      dismissed = completions.dismissed.count

      {
        total_started: total,
        completed: completed,
        dismissed: dismissed,
        in_progress: total - completed - dismissed,
        completion_rate: total > 0 ? (completed.to_f / total * 100).round(1) : 0
      }
    end

    def drop_off_per_step
      steps = @tour.steps.order(:position)
      steps.map do |step|
        reached = @tour.completions.where("step_id = ? OR step_id IN (?)", step.id,
          @tour.steps.where("position >= ?", step.position).pluck(:id)).count
        completed_at_step = @tour.completions.where(step: step, status: %w[dismissed]).count

        {
          step_id: step.id,
          title: step.title,
          position: step.position,
          reached: reached,
          dropped: completed_at_step
        }
      end
    end

    def ab_breakdown
      return [] if @tour.ab_test_id.blank?

      @tour.completions.group(:ab_group).select(
        "ab_group",
        "COUNT(*) as total",
        "COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count"
      ).map do |row|
        {
          group: row.ab_group,
          total: row.total,
          completed: row.completed_count,
          rate: row.total > 0 ? (row.completed_count.to_f / row.total * 100).round(1) : 0
        }
      end
    end
  end
end
```

- [ ] **Step 4: Run stats tests**

```bash
bundle exec rspec spec/services/onboard_on_rails/stats_calculator_spec.rb
```

Expected: All pass.

- [ ] **Step 5: Write stats controller and view**

Create `app/controllers/onboard_on_rails/admin/stats_controller.rb`:
```ruby
module OnboardOnRails
  module Admin
    class StatsController < BaseController
      def show
        @tour = Tour.find(params[:tour_id])
        calculator = StatsCalculator.new(@tour)
        @summary = calculator.summary
        @drop_off = calculator.drop_off_per_step
        @ab_breakdown = calculator.ab_breakdown
      end
    end
  end
end
```

Create `app/views/onboard_on_rails/admin/stats/show.html.erb`:
```erb
<div class="oor-page-header">
  <h1>Stats: <%= @tour.name %></h1>
  <%= link_to "Back to Tour", edit_admin_tour_path(@tour), class: "oor-btn oor-btn--secondary" %>
</div>

<!-- Summary -->
<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 24px;">
  <div class="oor-panel" style="text-align: center;">
    <div style="font-size: 32px; font-weight: 700; color: var(--oor-primary);"><%= @summary[:total_started] %></div>
    <div style="font-size: 13px; color: var(--oor-text-muted);">Started</div>
  </div>
  <div class="oor-panel" style="text-align: center;">
    <div style="font-size: 32px; font-weight: 700; color: var(--oor-success);"><%= @summary[:completed] %></div>
    <div style="font-size: 13px; color: var(--oor-text-muted);">Completed</div>
  </div>
  <div class="oor-panel" style="text-align: center;">
    <div style="font-size: 32px; font-weight: 700; color: var(--oor-danger);"><%= @summary[:dismissed] %></div>
    <div style="font-size: 13px; color: var(--oor-text-muted);">Dismissed</div>
  </div>
  <div class="oor-panel" style="text-align: center;">
    <div style="font-size: 32px; font-weight: 700;"><%= @summary[:completion_rate] %>%</div>
    <div style="font-size: 13px; color: var(--oor-text-muted);">Completion Rate</div>
  </div>
</div>

<!-- Drop-off per step -->
<div class="oor-panel" style="margin-bottom: 24px;">
  <h3 class="oor-panel__title">Drop-off per Step</h3>
  <table class="oor-table">
    <thead>
      <tr>
        <th>#</th>
        <th>Step</th>
        <th>Reached</th>
        <th>Dropped</th>
      </tr>
    </thead>
    <tbody>
      <% @drop_off.each do |step| %>
        <tr>
          <td><%= step[:position] %></td>
          <td><%= step[:title] %></td>
          <td><%= step[:reached] %></td>
          <td><%= step[:dropped] %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>

<!-- A/B Breakdown -->
<% if @ab_breakdown.any? %>
  <div class="oor-panel">
    <h3 class="oor-panel__title">A/B Test Results</h3>
    <table class="oor-table">
      <thead>
        <tr>
          <th>Group</th>
          <th>Total</th>
          <th>Completed</th>
          <th>Rate</th>
        </tr>
      </thead>
      <tbody>
        <% @ab_breakdown.each do |group| %>
          <tr>
            <td><span class="oor-badge oor-badge--active"><%= group[:group] %></span></td>
            <td><%= group[:total] %></td>
            <td><%= group[:completed] %></td>
            <td><%= group[:rate] %>%</td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
<% end %>
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add StatsCalculator service and admin stats view"
```

---

## Task 26: Selector Picker Stimulus Controller

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/admin/selector_picker_controller.js`

- [ ] **Step 1: Write picker Stimulus controller for step editor integration**

Create `app/assets/javascripts/onboard_on_rails/admin/selector_picker_controller.js`:
```javascript
(() => {
  const application = window.Stimulus || (window.Stimulus = Stimulus.start());

  application.register("selector-picker", class extends Stimulus.Controller {
    static targets = ["input"];

    connect() {
      window.addEventListener("message", this.handleMessage.bind(this));
    }

    disconnect() {
      window.removeEventListener("message", this.handleMessage.bind(this));
    }

    handleMessage(event) {
      if (event.data && event.data.type === "oor-selector-picked") {
        if (this.hasInputTarget) {
          this.inputTarget.value = event.data.selector;
          this.inputTarget.dispatchEvent(new Event("input"));
        }
      }
    }
  });
})();
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add Stimulus selector picker controller for postMessage integration"
```

---

## Task 27: Sortable Steps Stimulus Controller

**Files:**
- Create: `app/assets/javascripts/onboard_on_rails/admin/sortable_controller.js`

- [ ] **Step 1: Write sortable controller**

Create `app/assets/javascripts/onboard_on_rails/admin/sortable_controller.js`:
```javascript
(() => {
  const application = window.Stimulus || (window.Stimulus = Stimulus.start());

  application.register("sortable", class extends Stimulus.Controller {
    static targets = ["item"];
    static values = { url: String };

    connect() {
      this.itemTargets.forEach(item => {
        item.draggable = true;
        item.addEventListener("dragstart", this.dragStart.bind(this));
        item.addEventListener("dragover", this.dragOver.bind(this));
        item.addEventListener("drop", this.drop.bind(this));
        item.addEventListener("dragend", this.dragEnd.bind(this));
      });
    }

    dragStart(e) {
      this.draggedItem = e.currentTarget;
      e.currentTarget.style.opacity = "0.4";
      e.dataTransfer.effectAllowed = "move";
    }

    dragOver(e) {
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      const target = e.currentTarget;
      if (target !== this.draggedItem) {
        const rect = target.getBoundingClientRect();
        const midY = rect.top + rect.height / 2;
        if (e.clientY < midY) {
          target.parentNode.insertBefore(this.draggedItem, target);
        } else {
          target.parentNode.insertBefore(this.draggedItem, target.nextSibling);
        }
      }
    }

    drop(e) {
      e.preventDefault();
      this.saveOrder();
    }

    dragEnd(e) {
      e.currentTarget.style.opacity = "1";
      this.draggedItem = null;
    }

    saveOrder() {
      const items = this.element.querySelectorAll("[data-step-id]");
      const order = Array.from(items).map((item, i) => ({
        id: item.dataset.stepId,
        position: i + 1
      }));

      if (this.urlValue) {
        const csrfToken = document.querySelector('meta[name="csrf-token"]');
        fetch(this.urlValue, {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken ? csrfToken.content : ""
          },
          body: JSON.stringify({ order })
        });
      }
    }
  });
})();
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "feat: add Stimulus sortable controller for drag-to-reorder steps"
```

---

## Task 28: Run Full Test Suite & Final Verification

- [ ] **Step 1: Run the full test suite**

```bash
cd /Users/aleksandrsvajkin/develop/onboard_on_rails
bundle exec rspec
```

Expected: All tests pass.

- [ ] **Step 2: Fix any failures found**

Address any test failures from integration issues.

- [ ] **Step 3: Final commit**

```bash
git add -A
git commit -m "chore: fix any integration issues from full test run"
```

---

## Task 29: Add .gitignore and Clean Up

- [ ] **Step 1: Create .gitignore**

Create `.gitignore`:
```
*.gem
*.rbc
/.config
/coverage/
/InstalledFiles
/pkg/
/spec/reports/
/spec/examples.txt
/test/tmp/
/test/version_tmp/
/tmp/
.superpowers/

## Documentation cache and generated files:
/.yardoc/
/_yardoc/
/doc/
/rdoc/

## Environment normalization:
/.bundle/
/vendor/bundle
/lib/bundler/man/

## Dummy app
/spec/dummy/db/*.sqlite3
/spec/dummy/db/*.sqlite3-journal
/spec/dummy/db/*.sqlite3-shm
/spec/dummy/db/*.sqlite3-wal
/spec/dummy/log/*.log
/spec/dummy/tmp/

## IDE
.idea/
.vscode/
*.swp
*.swo

## OS
.DS_Store
Thumbs.db
```

- [ ] **Step 2: Commit**

```bash
git add -A
git commit -m "chore: add .gitignore and finalize project structure"
```
