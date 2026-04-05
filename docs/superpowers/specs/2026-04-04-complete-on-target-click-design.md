# Complete on Target Click — Design Spec

## Problem

When a tour step is attached to an interactive element (e.g., a "Create course" button), the user clicks that element expecting the step to complete. Instead, the step only completes via the "Done"/"Next" button in the tooltip. When the user returns to the page, the step reappears until they manually click "Done".

## Solution

Add an optional per-step boolean flag `complete_on_target_click`. When enabled, clicking the target element (the one matched by `selector`) counts as completing the step — same as clicking "Next"/"Done" in the tooltip.

## Design Decisions

- **Per-step setting** (not per-tour) — each step independently controls whether target click completes it.
- **Tooltip stays on screen** after target click — the natural page transition (if any) removes it. No explicit cleanup needed.
- **`navigator.sendBeacon()`** for the API call — guarantees delivery even if the click triggers page navigation. Fire-and-forget; no need for `preventDefault` or replaying the click.
- **Simple click listener on target element** (not event delegation, not MutationObserver) — OnboardOnRails targets Rails apps where DOM elements are stable. Simplest approach with minimal code.

## Database

Add column to `onboard_on_rails_steps`:

```ruby
add_column :onboard_on_rails_steps, :complete_on_target_click, :boolean, default: false, null: false
```

No validations needed — `selector` is already required on Step, so the target element always exists.

## API Serialization

`GET /api/tours` response includes `complete_on_target_click` for each step:

```json
{
  "steps": [
    {
      "id": 1,
      "selector": ".create-course-btn",
      "complete_on_target_click": true,
      ...
    }
  ]
}
```

No changes to `POST /api/completions` — the endpoint already accepts the same payload format that `sendBeacon` will send.

## Client-Side Logic

### On `showStep()`

1. Check `step.complete_on_target_click`.
2. If `true`, find the target element via `step.selector`.
3. Attach a `click` listener to the target element.
4. Store the element reference and bound handler for later cleanup.

### On target click

1. Build the completion payload (same structure as `ApiClient.updateCompletion`):
   - If last step: `status: "completed"`
   - If not last step: `status: "in_progress"`, `step_id` = next step's ID
2. Send via `navigator.sendBeacon(url, blob)` where blob is JSON with `Content-Type: application/json`.
3. Include `matched_url` and `matched_step_id` for multi-page tour state tracking.
4. Remove the click listener from the element.

### CSRF

`Api::BaseController` has `skip_forgery_protection`, so no CSRF token needed in the `sendBeacon` payload.

### Idempotency

Both the target click path and the tooltip button path produce the same API call. `CompletionsController#create` uses `find_or_initialize_by(tour_id, user_id)`, so double-firing is harmless.

### Listener cleanup

On step change or tour cleanup, remove any active target click listener. Store `{ element, handler }` reference on TourManager for `removeEventListener`.

## Admin UI

Add a checkbox in the step form (`_form.html.erb`) after the `selector` field:

```
☐ Засчитывать клик по элементу / Complete on target click
```

### Strong params

Add `:complete_on_target_click` to `step_params` in `Admin::StepsController`.

### Locales

- `en.yml`: `complete_on_target_click: "Complete on target click"`
- `ru.yml`: `complete_on_target_click: "Засчитывать клик по элементу"`

## Tests

### Model spec (`step_spec.rb`)
- `complete_on_target_click` defaults to `false`
- Persists `true` correctly

### API tours controller spec
- `complete_on_target_click` field is present in JSON response

### Admin steps controller spec
- Checkbox value saves through strong params

### No new completions controller tests
- `sendBeacon` sends the same payload format as the existing fetch — server-side logic is unchanged and already covered.

### No JS tests
- No JS test framework in the project. Manual verification.
