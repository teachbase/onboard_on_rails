# Configurable Accent Color

## Problem

The admin panel and client-side tour defaults use a hardcoded purple accent color (`#6c5ce7`). This color is too opinionated for a white-label engine. The default should be neutral (`#2d3436`), and host apps should be able to configure it.

## Solution

Add `accent_color` to `OnboardOnRails::Configuration`. A single hex string that drives the admin panel theme and serves as the default `button_color` for tours/steps.

Default: `#2d3436`.

## Configuration API

```ruby
OnboardOnRails.configure do |config|
  config.accent_color = "#2d3436"  # default
end
```

### Derived colors

`Configuration` exposes computed methods — no extra config needed:

- `accent_color_dark` — darken by 15% (for hover states)
- `accent_color_light` — lighten by 40% (for subtle backgrounds, hover borders)
- `accent_color_rgba(alpha)` — rgba string (for focus shadows, icon backgrounds)

Implementation: pure Ruby arithmetic on RGB components of the hex string. No gems.

## Changes

### 1. `lib/onboard_on_rails/configuration.rb`

Add `attr_accessor :accent_color` with default `"#2d3436"`.

Add private helper `hex_to_rgb` / `rgb_to_hex` and public methods:

```ruby
def accent_color_dark
  darken(accent_color, 0.15)
end

def accent_color_light
  lighten(accent_color, 0.40)
end

def accent_color_rgba(alpha)
  r, g, b = hex_to_rgb(accent_color)
  "rgba(#{r}, #{g}, #{b}, #{alpha})"
end
```

### 2. Admin layout — inject CSS variables

In the admin layout (rendered by `Admin::BaseController`), add a `<style>` block that overrides `admin.css` defaults:

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

### 3. `admin.css` — replace hardcoded rgba values

- Focus box-shadow `rgba(108, 92, 231, 0.15)` → `var(--oor-primary-shadow)`
- Stat card icon `.oor-stat-card__icon--started` background `rgba(108, 92, 231, 0.12)` → `var(--oor-primary-bg)`
- Update default `:root` values from `#6c5ce7` to `#2d3436` (and derived) as fallbacks

### 4. Admin views — replace hardcoded `#6c5ce7` defaults

In `tours/_form.html.erb`, `steps/_form.html.erb`, `steps/_preview.html.erb`:
- Replace `'#6c5ce7'` fallback with `OnboardOnRails.configuration.accent_color`

### 5. `selector_picker/show.html.erb`

Replace two hardcoded `#6c5ce7` references with `<%= OnboardOnRails.configuration.accent_color %>`.

### 6. Client-side default — meta tag + JS

**`meta_tags_helper.rb`**: add meta tag:
```ruby
tag.meta(name: "onboard-on-rails-accent-color",
         content: OnboardOnRails.configuration.accent_color)
```

**`client.js`**: in `TourManager.init()`, read the meta tag and set `--oor-step-btn-bg` on document root if no tour-level `button_color` override exists. The `ThemeEngine.applyTheme` already handles per-tour/step overrides via `style_overrides.button_color`.

**`client.css`**: change default `--oor-step-btn-bg: #4361ee` → `--oor-step-btn-bg: #2d3436`.

## What does NOT change

- `spec/dummy/` files — host app styles, not engine responsibility
- `docs/superpowers/plans/` — archived plans
- `style_overrides` structure — `button_color` still overrides per tour/step
- No new gem or npm dependencies

## Testing

- Unit test `Configuration`: default value `#2d3436`, custom value, `accent_color_dark`, `accent_color_light`, `accent_color_rgba`
- Run full suite `bundle exec rspec` — no regressions
