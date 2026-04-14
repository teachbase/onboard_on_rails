# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

OnboardOnRails is a **mountable Rails engine gem** (`isolate_namespace OnboardOnRails`) that adds an admin panel for building onboarding tours. It has no front-end framework dependency — both the admin UI and the end-user tour runtime are vanilla JS delivered through Sprockets. PostgreSQL is required (`jsonb` columns for `url_pattern`, `segment_rules`, `style_overrides`). All tables are prefixed `onboard_on_rails_` and every model sets `self.table_name` explicitly — do not rename.

## Commands

```bash
bundle exec rspec                                # full suite
bundle exec rspec spec/services/tour_matcher_spec.rb       # one file
bundle exec rspec spec/services/tour_matcher_spec.rb:42    # one example by line

# Dummy app (dev server + DB — required for manual testing)
cd spec/dummy && bin/rails db:setup              # first time
cd spec/dummy && RAILS_ENV=development bin/rails server
# then visit http://localhost:3000/onboard/admin
```

There is no linter configured. `bundle exec rake` runs the spec suite (default task).

## Architecture

### Four models, one request pipeline

`Tour` → `Step` (ordered, has jsonb `style_overrides`), plus `Completion` (per-user progress: `in_progress` / `completed` / `dismissed`) and `Event` (for event-triggered tours). A single client request to `GET /onboard/api/tours?url=…&session_id=…` is filtered through `TourMatcher`, which composes — in this order — active-status, URL pattern match (`UrlMatchable`), segment rules (`SegmentEvaluator`), frequency cap against `Completion`, event trigger against `Event`, and A/B assignment via `AbAssigner`. To understand how a tour is (or isn't) shown, read those components together — the logic is split across the service and the two concerns, not centralized.

### Auth bridging to the host app

Both `Admin::BaseController` and `Api::BaseController` resolve the current user by instantiating `::ApplicationController.new`, copying the request onto it, and calling the configured `current_user_method`. Admin controllers additionally gate with the `admin_auth` lambda from `OnboardOnRails.configuration`. API controllers `skip_forgery_protection`. This bridge works for auth libs that read from `request` (Devise/Warden), but host auth that depends on other `before_action` side-effects can break — keep this in mind when debugging "why is current_user nil inside the engine."

### Configuration DSL

`OnboardOnRails.configure` exposes `user_class`, `current_user_method`, `admin_auth`, and `register_attribute(key, type:, label:, description:, values:) { |user| … }`. Registered attributes are what the admin UI offers as targeting conditions and what `SegmentEvaluator` reads at match time. Types: `:string` (operators: `eq, not_eq, in, not_in, starts_with, ends_with, contains, not_contains, matches, length_gt, length_lt`), `:number` (`eq, not_eq, in, not_in, gt, lt, gte, lte`), `:boolean` (`eq`). Providing `values:` renders a dropdown instead of a text input.

### jsonb shapes (non-obvious)

- **`url_pattern`**: array of strings. Admin form posts a comma-separated string; `ToursController#tour_params` splits it. Direct API / console callers must pass an array. Match grammar: `*` = one path segment, `**` = any depth, leading `\` = regex mode.
- **`segment_rules`**: `{ "logic": "and"|"or", "conditions": [{ "attribute": "plan", "operator": "eq", "value": "pro" }] }`.
- **`style_overrides`** (on both `Tour` and `Step`): step overrides merge on top of tour overrides. Keys: `background_color`, `text_color`, `font_family`, `font_size`, `border_radius`, `button_color`.

### A/B testing

Create multiple tours sharing an `ab_test_id` with distinct `ab_test_group` values. `AbAssigner` uses `SHA256(user_id + ab_test_id)` modulo group count — deterministic per user, so re-visits land in the same variant.

### Self-tour lessons

Tours with `ab_test_id = "self_tour"` are the built-in admin-panel tutorials (content in Russian). `SelfTourSeeder.seed!` creates them; the admin "Replay" action deletes the current user's `Completion` rows for the lesson and redirects to its target page.

### Client/admin JS conventions

- Vanilla JS only — no Stimulus, React, jQuery, Turbo, or UJS. Entry points are `app/assets/javascripts/onboard_on_rails/{client,admin}.js`, each using Sprockets `//= require_tree` to pull its subdirectory.
- Client modules attach to `window.OnboardOnRails`. `TourManager.init()` runs on `DOMContentLoaded`. Public client API: `OnboardOnRails.trackEvent(name, payload)`.
- Admin "controllers" (`*_controller.js`) are plain objects despite the name — they are **not** Stimulus controllers. Don't reintroduce Stimulus.
- Delete actions use `button_to` (not `link_to method: :delete`) so the engine has zero UJS/Turbo dependency.

### i18n

`config/locales/{en,ru}.yml`. All view strings go through `t()`; ActiveRecord validation messages are also localized in `ru.yml`. Keep both locales in sync when adding user-facing strings.

## Do NOT

- Modify `spec/dummy/` files unless the change is specifically about the dummy app — it exists for dev/test only and is not shipped.
- Add framework dependencies (Stimulus, React, jQuery, Turbo) to client or admin JS.
- Change table names or remove `self.table_name` from models — the engine's isolated namespace depends on the explicit prefixes.
