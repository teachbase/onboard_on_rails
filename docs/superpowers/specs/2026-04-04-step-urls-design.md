# Multi-Page Tour Steps (Step URLs)

## Problem

Tours that span multiple pages don't work. Three interrelated issues:

1. **State lost on navigation** — `TourManager.currentStepIndex` lives in JS memory, resets on page load. Tours always restart from step 0.
2. **Redirect loops** — `showStep()` redirects to step's `url_pattern`, page reloads, tour starts over, redirects again.
3. **Selector picker locked to tour URL** — picker always opens on the tour's page. Can't pick selectors from a step's target page.

## Design Decisions

- **Step URL resolution**: each step can have its own `url_pattern` (supports globs). If empty, step shows on the current page (no inheritance from tour URL).
- **State persistence**: server-side via Completion records. `matched_url` field stores the actual URL where the step activated.
- **Navigation**: full bidirectional — "Back" redirects to saved `matched_url` of previous step if on a different page.
- **Matching**: step `url_pattern` uses the same glob/regex logic as tour `url_pattern` (via `UrlMatchable`), wrapped in a single-element array.

## Changes

### Database

New migration: add `matched_url` (string, nullable) to `onboard_on_rails_completions`.

### Model: Step

Add `matches_step_url?(url)` method that wraps `url_pattern` in an array and applies the same matching logic from `UrlMatchable`:

```ruby
def matches_step_url?(url)
  return true if url_pattern.blank?
  patterns = [url_pattern]
  # reuse UrlMatchable glob/regex logic
end
```

### Service: TourMatcher

Before normal matching, check for in-progress tours:

1. Find tours where user has `in_progress` completions but no `completed`/`dismissed` completion.
2. For that tour, compute `current_step_index` = index of step after last `in_progress` completion.
3. Check if current URL matches the current step (via `step.matches_step_url?` or tour's `matches_url?` if step has no url_pattern).
4. If match — return this tour with `current_step_index`.
5. If no match (user on unrelated page) — fall through to normal matching.

In-progress tour takes priority over new tour matches.

### API: tours_controller

Extend response with `current_step_index` and `matched_url` per step:

```json
{
  "tour": {
    "id": 5,
    "current_step_index": 2,
    "steps": [
      { "id": 1, "url_pattern": null, "matched_url": "/teacher/students", ... },
      { "id": 2, "url_pattern": "users/*/about", "matched_url": "/users/42/about", ... },
      { "id": 3, "url_pattern": null, "matched_url": null, ... }
    ]
  }
}
```

`matched_url` comes from the Completion record for that step+user. `null` if step hasn't been reached yet.

### API: completions_controller

- Accept `matched_url` parameter. Store it when creating/updating completion records.
- Add `DELETE /api/completions` endpoint (accepts `tour_id` + `step_id`) — used by `prev()` to roll back step progress.

### Client: client.js

**`loadTour()`**: use `tour.current_step_index` instead of always starting at 0.

**`showStep()`**:
- If step has `url_pattern` without globs and current URL doesn't match — redirect to `url_pattern`.
- If step has `url_pattern` with globs (`*`) — don't redirect (can't navigate to a glob). Assume user is on correct page since server returned this step.
- If step has no `url_pattern` — show on current page.

**`next()`**:
- Send `matched_url: window.location.pathname` with completion request.
- If next step is on a different URL — browser navigates, `loadTour()` on new page resumes via server state.

**`prev()`**:
- Delete the completion for the current step (so server-side `current_step_index` moves back correctly).
- If previous step's `matched_url` differs from current URL — redirect to `matched_url`.
- Otherwise show previous step in place.

**Remove `matchesCurrentUrl()`** — matching now handled server-side.

### Admin: Step Form

- Move `url_pattern` field above `selector` field (set URL first, then pick element).
- Selector picker button passes `url: step.url_pattern` if filled and not a glob.

### Selector Picker Controller

`resolve_target_url` priority:
1. `params[:url]` (explicit override)
2. `step.url_pattern` (if present and not a glob)
3. Tour's first `url_pattern` (stripped of globs, as current behavior)
4. `"/"`

### Self-Tour Lessons

Update `SelfTourSeeder` lesson content to cover:
- Setting `url_pattern` on steps for multi-page tours
- How navigation works across pages

### Admin: Recreate Lessons Button

Add button on `lessons/index` page:
- Calls `SelfTourSeeder.seed!` to upsert lessons
- Deletes completions for self-tour lessons for current user
- Redirects back to lessons index

### Locales

Update en.yml and ru.yml:
- Hint for step `url_pattern`: mention glob support, explain it determines which page the step appears on
- Label/flash for "Recreate lessons" button

## Files to Modify

| File | Change |
|------|--------|
| `db/migrate/new` | Add `matched_url` to completions |
| `app/models/onboard_on_rails/step.rb` | Add `matches_step_url?` |
| `app/services/onboard_on_rails/tour_matcher.rb` | In-progress tour resumption logic |
| `app/controllers/onboard_on_rails/api/tours_controller.rb` | Add `current_step_index`, `matched_url` to response |
| `app/controllers/onboard_on_rails/api/completions_controller.rb` | Accept `matched_url` param, add DELETE endpoint |
| `app/controllers/onboard_on_rails/admin/lessons_controller.rb` | Add `recreate` action |
| `app/controllers/onboard_on_rails/selector_picker_controller.rb` | Use step url_pattern |
| `app/views/onboard_on_rails/admin/steps/_form.html.erb` | Reorder fields, pass URL to picker |
| `app/views/onboard_on_rails/admin/lessons/index.html.erb` | Add recreate button |
| `app/assets/javascripts/onboard_on_rails/client.js` | All client-side navigation changes |
| `app/services/onboard_on_rails/self_tour_seeder.rb` | Update lesson content |
| `config/locales/en.yml` | New/updated labels and hints |
| `config/locales/ru.yml` | New/updated labels and hints |
| `config/routes.rb` | Add `recreate` route for lessons |
