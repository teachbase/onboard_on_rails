# CLAUDE.md — AI Agent Context for OnboardOnRails

## Project Overview

OnboardOnRails is a **Rails engine gem** that provides an admin panel for creating and managing onboarding tours. It is mountable, uses an isolated namespace (`OnboardOnRails`), and all database tables are prefixed with `onboard_on_rails_`.

Version: 0.1.0  
License: MIT  
Ruby: >= 3.1, Rails: >= 7.0, PostgreSQL required (jsonb columns).

## Directory Structure

```
app/
  models/onboard_on_rails/
    tour.rb              # Core model: name, status, theme, targeting, scheduling, A/B
    step.rb              # Belongs to tour: selector, placement, body, style_overrides
    completion.rb        # Tracks user progress: in_progress / completed / dismissed
    event.rb             # Custom events for event-triggered tours
    concerns/
      url_matchable.rb   # Glob/regex URL matching (*, **)
      segment_evaluator.rb # Attribute-based condition evaluation (eq, in, gt, etc.)
  controllers/onboard_on_rails/
    application_controller.rb    # Base: ActionController::Base + forgery protection
    admin/
      base_controller.rb         # Auth via admin_auth lambda, current_user delegation
      tours_controller.rb        # CRUD for tours
      steps_controller.rb        # CRUD for steps (nested under tours)
      stats_controller.rb        # Statistics page per tour
      lessons_controller.rb      # Self-tour lesson management + replay
    api/
      base_controller.rb         # skip_forgery_protection, authenticate_user!
      tours_controller.rb        # GET /api/tours?url=...&session_id=...
      completions_controller.rb  # POST /api/completions
      events_controller.rb       # POST /api/events
    selector_picker_controller.rb # iframe-based visual element picker
  services/onboard_on_rails/
    tour_matcher.rb      # Filters active tours by URL, segment, frequency, event, A/B
    ab_assigner.rb       # Deterministic SHA256-based A/B group assignment
    stats_calculator.rb  # Summary, drop-off per step, A/B breakdown
    self_tour_seeder.rb  # Creates built-in tutorial lessons (3 tours)
  helpers/onboard_on_rails/
    meta_tags_helper.rb  # Injects user-id, mount-path, csrf-token meta tags
  assets/
    javascripts/onboard_on_rails/
      client.js          # Entry: //= require_tree ./client
      client/
        api_client.js    # fetch wrapper for tours/completions/events API
        tour_manager.js  # Init, load, navigate, dismiss, complete tours
        tour_renderer.js # DOM: overlay, tooltip, highlight, cleanup
        theme_engine.js  # Apply tooltip/modal/banner/slideout themes + style overrides
        positioning_engine.js  # Placement calculation (top/bottom/left/right/center)
        dom_observer.js  # MutationObserver for SPA navigation + waitForSelector
        selector_generator.js  # Generate unique CSS selectors for picker
      admin.js           # Entry: //= require_tree ./admin
      admin/
        step_preview_controller.js     # Live step preview in edit form
        segment_rules_controller.js    # Dynamic segment rule builder
        sortable_controller.js         # Step reordering
        selector_picker_controller.js  # Selector picker iframe communication
    stylesheets/onboard_on_rails/
      admin.css          # Admin panel styles
      client.css         # Tour overlay, tooltip, themes
config/
  routes.rb             # admin/ namespace + api/ namespace + selector_picker
  locales/
    en.yml              # English translations
    ru.yml              # Russian translations
db/migrate/
  ..._create_onboard_on_rails_tours.rb
  ..._create_onboard_on_rails_steps.rb
  ..._create_onboard_on_rails_completions.rb
  ..._create_onboard_on_rails_events.rb
lib/
  onboard_on_rails.rb           # Module: configure block + track_event helper
  onboard_on_rails/engine.rb    # isolate_namespace, i18n, helpers, asset precompile
  onboard_on_rails/configuration.rb  # user_class, admin_auth, user_attributes, current_user_method
  onboard_on_rails/version.rb   # VERSION = "0.1.0"
spec/
  models/         # Tour, Step, Completion, Event model specs
  concerns/       # UrlMatchable, SegmentEvaluator specs
  services/       # TourMatcher, AbAssigner, StatsCalculator specs
  controllers/    # Admin + API controller specs
  dummy/          # Rails dummy app for development and testing
```

## Key Patterns

### Engine Isolation
- `isolate_namespace OnboardOnRails` in `engine.rb`
- All tables: `onboard_on_rails_tours`, `onboard_on_rails_steps`, `onboard_on_rails_completions`, `onboard_on_rails_events`
- Models set `self.table_name` explicitly

### Authentication & Authorization
- **Admin controllers** inherit from `Admin::BaseController`, which calls `authorize_admin!` using the `admin_auth` lambda from configuration
- **API controllers** inherit from `Api::BaseController` with `skip_forgery_protection` and `authenticate_user!`
- **current_user resolution**: both base controllers create a `::ApplicationController.new` instance, copy the request object, and call the configured `current_user_method` on it. This is how the engine accesses the host app's auth.

### Client JavaScript
- Vanilla JS, no Stimulus/React/jQuery dependency
- Uses Sprockets `//= require_tree` to load modules
- All modules attach to `window.OnboardOnRails` namespace
- `OnboardOnRails.TourManager.init()` runs on DOMContentLoaded
- `OnboardOnRails.trackEvent(name, payload)` is the public client-side API

### Admin JavaScript
- Vanilla JS (was originally Stimulus, rewritten to plain JS)
- Controllers are plain objects, not Stimulus controllers despite "controller" in filenames

### Locales
- `config/locales/en.yml` and `config/locales/ru.yml`
- All view strings use `t()` helper
- ActiveRecord error messages are also localized in ru.yml

### Self-Tour Lessons
- Tours with `ab_test_id = "self_tour"` are treated as lessons
- Created via `SelfTourSeeder.seed!`
- Lesson content is in Russian
- Replay deletes completions for the current user and redirects to target page

### URL Pattern Handling
- Stored as jsonb array in `url_pattern` column
- Admin form sends comma-separated string, controller splits into array in `tour_params`
- Matching: `*` = single path segment, `**` = any depth, backslash = regex mode

### Delete Buttons
- Use `button_to` (not `link_to method: :delete`) — no Turbo/UJS dependency required

## Testing

```bash
bundle exec rspec
```

- 14 spec files, ~75 examples
- Dummy app in `spec/dummy/` (PostgreSQL required)
- Factories defined with FactoryBot

## Running Dev Server

```bash
cd spec/dummy && RAILS_ENV=development bin/rails server
```

Then visit `http://localhost:3000/onboard/admin`.

## Common Gotchas

1. **current_user resolution**: The engine instantiates `::ApplicationController.new` and delegates — if the host app's `current_user` relies on instance variables set by before_actions (e.g., Devise's `warden`), this works because `request` is shared. But custom auth that depends on other before_actions may need adjustment.

2. **url_pattern jsonb**: The admin form sends a comma-separated string. The `tour_params` method in `ToursController` splits it into an array. Direct API or console usage should pass an array.

3. **segment_rules jsonb**: Expected format is `{ "logic": "and"|"or", "conditions": [{ "attribute": "plan", "operator": "eq", "value": "pro" }] }`.

4. **style_overrides**: Both Tour and Step have `style_overrides` (jsonb). Step overrides merge on top of tour overrides. Keys: `background_color`, `text_color`, `font_family`, `font_size`, `border_radius`, `button_color`.

5. **A/B testing**: Create multiple tours with the same `ab_test_id` but different `ab_test_group` values. `AbAssigner` uses SHA256(user_id + ab_test_id) for deterministic assignment.

## Do NOT

- Modify `spec/dummy/` files unless you are specifically testing the dummy app — it is for development only.
- Add framework dependencies (Stimulus, React, jQuery) to client or admin JS.
- Change table names or remove `self.table_name` from models.
