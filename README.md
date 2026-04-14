# OnboardOnRails

A universal onboarding tour engine for Ruby on Rails. Mount a full-featured admin panel into your app and create interactive product tours — no front-end framework required.

## Features

- **Admin Panel** — create and manage tours, steps, and lessons from a browser UI
- **Visual Selector Picker** — point-and-click CSS selector builder (iframe-based)
- **4 Themes** — Tooltip, Modal, Banner, Slideout — configurable per tour and per step
- **A/B Testing** — split users into deterministic groups, compare completion rates
- **User Targeting** — DSL for registering targetable attributes with 15 operators (eq, starts_with, contains, matches, in, gt, etc.)
- **Scheduling** — set start/end dates for time-limited tours
- **Frequency Control** — once, every session, or always
- **Trigger Types** — auto (page load), event-based, or manual via API
- **SSR + SPA support** — vanilla JS client works with Turbo, React, or classic Rails
- **i18n** — English and Russian out of the box
- **Self-Tour Lessons** — built-in interactive tutorials that teach the admin panel itself
- **Statistics** — completion rates, drop-off per step, A/B breakdown

## Requirements

- Ruby >= 3.1
- Rails >= 7.0
- PostgreSQL (jsonb columns for url_pattern, segment_rules, style_overrides)

## Quick Installation

### 1. Add the gem

```ruby
# Gemfile
gem "onboard_on_rails"
```

```bash
bundle install
```

### 2. Mount the engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount OnboardOnRails::Engine => "/onboard"
  # ...
end
```

### 3. Run migrations

```bash
bin/rails onboard_on_rails:install:migrations
bin/rails db:migrate
```

### 4. Create initializer

```ruby
# config/initializers/onboard_on_rails.rb
OnboardOnRails.configure do |config|
  config.user_class = "User"
  config.current_user_method = :current_user

  config.admin_auth = ->(controller) {
    controller.current_user&.admin?
  }

  config.register_attribute :email, type: :string, label: "Email" do |user|
    user.email
  end

  config.register_attribute :plan, type: :string, label: "Plan", values: ["free", "pro", "enterprise"] do |user|
    user.plan
  end
end
```

### 5. Add meta tags and assets to your layout

```erb
<%# app/views/layouts/application.html.erb %>
<head>
  <%= onboard_on_rails_meta_tags %>
  <%= javascript_include_tag "onboard_on_rails/client" %>
  <%= stylesheet_link_tag "onboard_on_rails/client" %>
</head>
```

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `user_class` | String | `"User"` | ActiveRecord model representing users |
| `admin_auth` | Lambda | `->(_) { true }` | Receives controller, returns true/false for admin access |
| `current_user_method` | Symbol | `:current_user` | Method name on your ApplicationController that returns the current user |
| `register_attribute` | DSL | — | Register a user attribute for targeting (see below) |

## User Targeting

Register attributes that can be used for targeting in the admin panel. Each attribute needs a type, label, and a block that extracts the value from the user object.

```ruby
OnboardOnRails.configure do |config|
  # String attributes — supports: eq, not_eq, in, not_in, starts_with, ends_with,
  #   contains, not_contains, matches (regex), length_gt, length_lt
  config.register_attribute :email, type: :string, label: "Email",
    description: "User email address" do |user|
    user.email
  end

  # String with predefined values — admin sees a dropdown instead of text input
  config.register_attribute :plan, type: :string, label: "Plan",
    description: "Subscription plan",
    values: ["free", "pro", "enterprise"] do |user|
    user.plan
  end

  # Number attributes — supports: eq, not_eq, in, not_in, gt, lt, gte, lte
  config.register_attribute :account_id, type: :number, label: "Account ID",
    description: "ID of the user's account" do |user|
    user.account_id
  end

  # Boolean attributes — supports: eq (true/false dropdown)
  config.register_attribute :admin, type: :boolean, label: "Admin?",
    description: "Whether the user is an admin" do |user|
    user.admin?
  end
end
```

### Parameters

| Parameter | Required | Description |
|---|---|---|
| `key` | yes | Symbol identifier (first argument) |
| `type` | yes | `:string`, `:number`, or `:boolean` |
| `label` | yes | Display name in the admin panel |
| `description` | no | Help text shown below the attribute selector |
| `values` | no | Array of allowed values (renders as dropdown in admin) |
| `block` | yes | `\|user\| -> value` — extracts the attribute value |

### Examples

Show a tour to users whose email starts with "foo":
- Attribute: `email`, Operator: `starts_with`, Value: `foo`

Show a tour to specific accounts:
- Attribute: `account_id`, Operator: `in`, Value: `123, 456, 789`

Show a tour to users with names longer than 10 characters:
- Attribute: `name`, Operator: `length_gt`, Value: `10`

Combine multiple conditions with AND/OR logic in the admin panel.

## Usage

1. Open the admin panel at `/onboard/admin`
2. Click **New Tour**, fill in name, URL pattern, theme, and trigger settings
3. Add steps — set CSS selector, placement, title, and body text
4. Use the visual selector picker to choose elements on your pages
5. Set the tour status to **Active**
6. Visit the target page as a logged-in user — the tour starts automatically

## Self-Tour Lessons

OnboardOnRails ships with built-in tutorials that teach admins how to use the panel:

- **Lesson 1**: Overview of the admin panel
- **Lesson 2**: Creating and configuring a tour
- **Lesson 3**: Adding and styling steps

To create them, go to `/onboard/admin/lessons` and click **Create Lessons**, or call:

```ruby
OnboardOnRails::SelfTourSeeder.seed!
```

## API

### Client-side (JavaScript)

```javascript
// Track a custom event
OnboardOnRails.trackEvent("first_project_created", { project_id: 42 });
```

### Server-side (Ruby)

```ruby
# Track an event for a user
OnboardOnRails.track_event(user, "subscription_activated", { plan: "pro" })
```

### REST Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/onboard/api/tours?url=/dashboard` | Fetch matching tour for URL |
| POST | `/onboard/api/completions` | Create/update completion record |
| POST | `/onboard/api/events` | Track a custom event |

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Rails Engine (mountable, isolated namespace) |
| Database | PostgreSQL with jsonb columns |
| Admin JS | Vanilla JavaScript (no framework) |
| Client JS | Vanilla JavaScript (no framework) |
| Asset pipeline | Sprockets |
| Styling | Plain CSS with custom properties |
| i18n | Rails I18n (en, ru) |
| Testing | RSpec + FactoryBot |

## Detailed Documentation

See [docs/setup.md](docs/setup.md) for comprehensive Russian documentation covering authentication, targeting, theming, A/B testing, API reference, and more.

## License

MIT
