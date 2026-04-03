# OnboardOnRails — Design Spec

## Overview

A Rails engine gem that provides a universal onboarding/announcement tour system. Admins create and manage tours through a web admin panel. Tours appear as overlays on any page, attach to DOM elements via CSS selectors, and work with both SSR (Hotwire/Turbo) and React apps hosted by Rails.

## Architecture

Monolithic Rails engine. Single gem provides: admin panel, JSON API, client-side JS tour player. Installed via `mount OnboardOnRails::Engine, at: '/onboard'`. Data stored in host app's database via engine migrations.

## Data Model

All tables prefixed `onboard_on_rails_`.

### tours

| Column | Type | Description |
|--------|------|-------------|
| name | string | Admin-facing name |
| description | text | Admin-facing description |
| status | string | `draft` / `active` / `archived` |
| trigger_type | string | `auto` (page load) / `event` (custom event) / `manual` (API call) |
| trigger_event | string | Event name if trigger_type is `event` |
| url_pattern | jsonb | URL masks where tour activates — single string or array of glob/regex patterns |
| segment_rules | jsonb | Targeting conditions (role, signup date, custom attributes) |
| schedule_start | datetime | Optional start of active window |
| schedule_end | datetime | Optional end of active window |
| frequency | string | `once` / `every_session` / `always` |
| ab_test_group | string | A/B group label (e.g. `A`, `B`) or null for all users |
| ab_test_id | string | Groups tours into the same A/B experiment |
| theme | string | Preset theme name (`tooltip` / `modal` / `banner` / `slideout`) |
| style_overrides | jsonb | Global style overrides for the tour |
| priority | integer | Resolves conflicts when multiple tours match (higher = shown first) |
| timestamps | | created_at, updated_at |

### steps

| Column | Type | Description |
|--------|------|-------------|
| tour_id | FK | Belongs to tour |
| position | integer | Step ordering |
| title | string | Step title |
| body | text | Step body (HTML allowed) |
| selector | string | CSS selector to attach to |
| placement | string | `top` / `bottom` / `left` / `right` / `center` |
| url_pattern | string | Optional, if step is on a different page |
| style_overrides | jsonb | Per-step style overrides |
| action_type | string | `next` / `redirect` / `custom_event` |
| action_value | string | URL for redirect, event name for custom_event |
| wait_for_selector | string | Optional, delay step until element appears |
| timestamps | | created_at, updated_at |

### completions

| Column | Type | Description |
|--------|------|-------------|
| tour_id | FK | Belongs to tour |
| user_id | bigint | Configurable user reference |
| step_id | FK | Last completed step (null = not started) |
| status | string | `in_progress` / `completed` / `dismissed` |
| ab_group | string | Which A/B group user was assigned to |
| session_id | string | For frequency logic |
| started_at | datetime | |
| completed_at | datetime | |
| timestamps | | created_at, updated_at |

### events

| Column | Type | Description |
|--------|------|-------------|
| user_id | bigint | User who triggered the event |
| name | string | Event name |
| payload | jsonb | Optional metadata |
| created_at | datetime | |

## Engine Structure

```
onboard_on_rails/
├── app/
│   ├── controllers/onboard_on_rails/
│   │   ├── admin/
│   │   │   ├── tours_controller.rb
│   │   │   ├── steps_controller.rb
│   │   │   └── settings_controller.rb
│   │   ├── api/
│   │   │   ├── tours_controller.rb
│   │   │   ├── events_controller.rb
│   │   │   └── completions_controller.rb
│   │   └── selector_picker_controller.rb
│   ├── models/onboard_on_rails/
│   │   ├── tour.rb
│   │   ├── step.rb
│   │   ├── completion.rb
│   │   └── event.rb
│   ├── views/onboard_on_rails/admin/
│   ├── assets/
│   │   ├── javascripts/onboard_on_rails/
│   │   │   ├── admin/          # Stimulus controllers for admin panel
│   │   │   └── client/         # Tour player engine
│   │   └── stylesheets/onboard_on_rails/
│   │       ├── admin.css
│   │       └── client.css
│   └── helpers/
├── config/routes.rb
├── db/migrate/
├── lib/
│   ├── onboard_on_rails.rb
│   ├── onboard_on_rails/engine.rb
│   └── onboard_on_rails/configuration.rb
└── onboard_on_rails.gemspec
```

## Installation in Host App

```ruby
# Gemfile
gem 'onboard_on_rails'

# config/routes.rb
mount OnboardOnRails::Engine, at: '/onboard'

# Terminal
rails onboard_on_rails:install:migrations
rails db:migrate
```

## Configuration

```ruby
# config/initializers/onboard_on_rails.rb
OnboardOnRails.configure do |config|
  config.user_class = 'User'
  config.admin_auth = ->(controller) { controller.current_user&.admin? }
  config.user_attributes = ->(user) {
    { role: user.role, plan: user.plan, signed_up_at: user.created_at }
  }
  config.current_user_method = :current_user
end
```

## Client JS Inclusion

```erb
<%= onboard_on_rails_meta_tags %>
<%= javascript_include_tag 'onboard_on_rails/client' %>
<%= stylesheet_link_tag 'onboard_on_rails/client' %>
```

The meta tag renders user ID and CSRF token for API calls.

## Client-Side Tour Player

Vanilla JS, no framework dependency. Key components:

### TourManager
Entry point. On page load, fetches `GET /onboard/api/tours?url=<current_path>`. Evaluates priority, manages tour lifecycle.

### TourRenderer
Creates overlay (semi-transparent backdrop with cutout around target element via CSS clip-path). Positions tooltip/modal/banner relative to target selector. Renders step content: title, body, progress dots, next/prev/dismiss/skip buttons.

### Positioning Engine
Calculates tooltip placement using `getBoundingClientRect()` + scroll offset. Falls back to opposite side if not enough space. Recalculates on resize/scroll.

### DOMObserver
Wraps `MutationObserver`. Handles dynamic DOM:
- `turbo:load` — re-fetches tours for new URL
- `turbo:before-render` — detaches current tooltip
- React re-renders — MutationObserver catches new elements, re-attaches
- `wait_for_selector` — delays step until element appears

### APIClient
Thin fetch wrapper for engine API endpoints.

### ThemeEngine
Applies preset theme CSS class + merges style overrides as CSS custom properties on the tooltip container.

### Tour Flow
1. Page loads → TourManager fetches matching tours
2. Highest priority tour selected → TourRenderer shows step 1
3. User clicks Next → completion API called, next step rendered
4. If next step has different `url_pattern` → redirect, tour resumes on new page
5. User completes or dismisses → completion status saved
6. On Turbo navigation → `turbo:load` → TourManager re-evaluates

## Admin Panel

Built with ERB + Hotwire (Turbo + Stimulus). Four main screens:

### Tours List
Table of all tours with columns: name, status (badge), step count, URL pattern, trigger type, priority. Filterable by status. Actions: edit, duplicate, archive/activate, delete.

### Tour Editor
Two-panel layout:
- **Left:** tour settings (name, description, URL pattern, trigger type/event, frequency) and targeting (segment rule builder, schedule, A/B test config)
- **Right:** step list with drag-to-reorder, add/remove steps

### Step Editor
Two-panel layout:
- **Left:** content (title, body), target (CSS selector input + visual picker button, placement selector), style overrides (background, text color, font family, font size, border radius, max width, shadow, button color)
- **Right:** live preview — renders the tooltip/modal on a simulated page, updates instantly as style settings change

### Theme Settings
Per-tour: select preset type (tooltip/modal/banner/slideout). Set global style overrides that apply to all steps unless overridden at step level.

## Visual Selector Picker

1. Admin clicks "Pick" in step editor
2. Iframe loads host app page through a proxy controller (handles same-origin)
3. Proxy injects picker JS, strips existing onboarding scripts
4. Hover highlights elements with blue outline
5. Click generates optimal CSS selector (`#id` > unique class > path-based)
6. Selector written back to step editor input
7. Toolbar at top of iframe shows current selector, confirm/cancel buttons
8. Admin can manually edit the auto-generated selector

## Targeting & Rules Engine

### URL Matching
- Glob patterns: `/dashboard/*`, `/settings/billing`
- Regex: `/projects/\d+/edit`
- Multiple patterns per tour (JSON array)

### User Segments
Visual rule builder in admin. Conditions combinable with AND/OR:
```
role = "admin" AND signed_up_at > "2026-01-01"
plan IN ["pro", "enterprise"] OR custom.onboarded = false
```
Available attributes sourced from `user_attributes` lambda in config.

### Event-Based Triggers
- Server-side: `OnboardOnRails.track_event(user, 'first_project_created')`
- Client-side: `OnboardOnRails.trackEvent('first_project_created')`
- Tour with `trigger_type: :event` activates when matching event exists

### Frequency Control
- `once` — one time per user
- `every_session` — once per session (tracked via session_id)
- `always` — every time conditions match

### A/B Testing
- Tours grouped by `ab_test_id`
- User assigned deterministically: hash of user_id + ab_test_id
- Completions track group assignment
- Admin sees conversion rates per group in stats view

### Scheduling
- `schedule_start` / `schedule_end` define active window
- Tour only served within this window

## API Endpoints

All under the engine mount path (e.g., `/onboard`).

### Client API

```
GET  /api/tours?url=/current/path
  → Active tours matching URL + user segments + schedule + frequency
  → Includes steps, styles, theme

POST /api/completions
  → { tour_id, step_id, status }
  → Tracks user progress

POST /api/events
  → { name, payload }
  → Client-side event tracking
```

### Admin API

```
GET  /api/tours/:id/stats
  → Completion rates, A/B breakdown, drop-off per step
```

### Authentication
- Client API uses host app session cookie (no separate auth)
- Admin endpoints protected by `admin_auth` lambda
- CSRF token via meta tag helper

### Performance
- Tours response cached per user + URL (invalidated on tour edit)
- Single DB query with eager-loaded steps
- Optional: preload tour URL patterns in meta tag so client JS skips API call on non-matching pages

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Engine | Rails engine (mountable) |
| Admin views | ERB + Hotwire (Turbo + Stimulus) |
| Admin styles | CSS (engine-scoped) |
| Client JS | Vanilla JS (no framework dependency) |
| Client styles | CSS with theme presets + custom properties |
| Database | Host app DB (PostgreSQL recommended for jsonb) |
| Asset delivery | Rails asset pipeline (Sprockets/Propshaft) |
