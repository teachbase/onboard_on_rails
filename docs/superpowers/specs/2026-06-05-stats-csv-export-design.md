# Tour Stats CSV Export — Design

**Date:** 2026-06-05
**Status:** Approved (design)

## Problem

On the tour stats page (`/admin/tours/:id/stats`) the **Completion History** table is
capped at the 50 most recent rows (`@tour.completions … .limit(50)`). Admins — typically
marketing — launch popups/tours and later need the **full list of users** who interacted
with a tour, especially those who **dismissed** it. The UI cannot give them that complete
list.

## Goal

Add an **"Export CSV"** button to the stats page that synchronously downloads a CSV file
containing the **complete** completion history (no 50-row limit), with user-identifying
fields configurable per host application.

## Scope

In scope:
- One CSV file = the full Completion History (one row per `Completion`).
- A download button on the stats page.
- Per-application configurable user columns, reusing the existing `register_attribute` DSL.

Out of scope (explicitly):
- Exporting the summary / drop-off / A/B sections (their numbers are derivable from the raw
  completion rows).
- Background/async generation (synchronous only — expected volume ≤ ~1,000 rows per tour).
- Streaming, pagination, XLSX, or multi-file/ZIP output.
- Any UI filtering of the export (recipients filter in their spreadsheet tool).

## CSV Contents

One table, all completion rows, ordered the same way as the UI (`updated_at: :desc`).

**Base columns (always present, independent of configuration):**

| Column | Source |
|---|---|
| `user_id` | `completion.user_id` |
| `user_email` | best-effort: `user.email` when the user model responds to `:email`, else blank |
| `status` | **raw** value (`completed` / `dismissed` / `in_progress`) — not localized, so it filters cleanly in a spreadsheet |
| `last_step_position` | `completion.step&.position` |
| `last_step_title` | `completion.step&.title` |
| `started_at` | formatted `%Y-%m-%d %H:%M:%S` (sortable, unambiguous), blank when nil |
| `completed_at` | same format, blank when nil |

**Configurable columns (per host app):**
One additional column per registered attribute from `OnboardOnRails.configuration`.
- Header = the attribute's `label`.
- Value = `attr_def.resolver.call(user)`.
- Order = registration order (`registered_attributes` is an insertion-ordered Hash).

This **reuses `register_attribute`** rather than introducing a new DSL — the host app already
declares these with a label and a resolver block. Email is kept as a guaranteed base column
because it is needed for the marketing use case but is not normally a targeting attribute.

**Edge case — user not found:** when `completion.user_id` has no matching user record,
`user_email` and all attribute columns are blank. The attribute resolvers are **not** called
for a nil user (avoids resolver crashes).

## Architecture

### New service: `OnboardOnRails::CompletionsCsvExporter`

Single-purpose, mirroring `StatsCalculator`'s shape.

```ruby
module OnboardOnRails
  class CompletionsCsvExporter
    def initialize(tour)
      @tour = tour
    end

    def filename
      "tour-#{@tour.id}-completions-#{Date.current.strftime('%Y%m%d')}.csv"
    end

    def to_csv
      # ... build CSV string (see below)
    end
  end
end
```

`#to_csv` responsibilities:
1. Load completions: `@tour.completions.includes(:step).order(updated_at: :desc)`.
2. **Avoid N+1**: collect `user_id`s, load all users in a single query
   (`user_class.where(id: ids).index_by(&:id)`), guarded when `user_class` is unset/invalid.
3. Resolve the registered attribute definitions once
   (`OnboardOnRails.configuration.registered_attributes.values`).
4. Build the header row: localized base headers (via i18n) + each attribute's `label`.
5. Emit one row per completion, looking the user up in the preloaded hash.
6. Use `CSV.generate` and prepend a **UTF-8 BOM** (`"﻿"`) so Excel reads Cyrillic/email
   correctly.

Email helper: best-effort `user.respond_to?(:email) ? user.email : nil`.

### Controller: `Admin::StatsController#export`

```ruby
def export
  @tour = Tour.find(params[:tour_id])
  exporter = CompletionsCsvExporter.new(@tour)
  send_data exporter.to_csv,
            filename: exporter.filename,
            type: "text/csv",
            disposition: "attachment"
end
```

Authorization is inherited from `Admin::BaseController` — the same `admin_auth` gate that
guards `show`/`destroy`. No new auth logic.

### Route

Add an `export` action to the existing singular `stats` resource:

```ruby
resource :stats, only: [:show, :destroy] do
  get :export
end
```

→ `GET /admin/tours/:tour_id/stats/export`, helper `export_admin_tour_stats_path`.

### View: button on the stats page

In `app/views/onboard_on_rails/admin/stats/show.html.erb`, inside
`.oor-page-header__actions`, add a plain GET download link (not `button_to`):

```erb
<%= link_to t("onboard_on_rails.admin.stats.export"),
    export_admin_tour_stats_path(@tour),
    class: "oor-btn oor-btn--sm" %>
```

A GET `link_to` keeps the engine free of UJS/Turbo (consistent with the "no framework JS"
rule); the file download needs no `method:` override.

## i18n

Add to **both** `config/locales/en.yml` and `config/locales/ru.yml`:

- Button: `onboard_on_rails.admin.stats.export`
- CSV base headers under `onboard_on_rails.admin.stats.csv.*`:
  `user_id`, `user_email`, `status`, `last_step_position`, `last_step_title`,
  `started_at`, `completed_at`.

Attribute column headers are **not** localized by the engine — they use the `label` provided
by the host application.

## Error Handling / Edge Cases

- No completions → CSV with the header row only (valid, openable file).
- `user_class` unconfigured or not resolvable → email and attribute columns blank, no crash.
- User model without `:email` → `user_email` blank.
- Missing user record for a `user_id` → email + attribute columns blank, resolvers skipped.

## Testing

**`spec/services/onboard_on_rails/completions_csv_exporter_spec.rb`**
- Header row = base columns + one per registered attribute (label as header).
- Exactly one row per completion, including a case with **more than 50** completions
  (proves the UI limit does not apply).
- `status` is the raw value, not a localized string.
- `user_email` populated when the user model responds to `:email`; blank otherwise.
- Registered-attribute columns take their value from the resolver block.
- Tour with no completions → header row only.
- Missing user → blank email + blank attribute cells.

**Controller/request spec for `#export`**
- `GET …/stats/export` returns `200`.
- `Content-Type: text/csv`.
- `Content-Disposition` is `attachment` with the expected filename.
- Body parses as CSV with the expected header.
- The `admin_auth` gate is exercised (consistent with existing stats specs).

## Decisions Not Derived From The Request

These were proposed and approved during brainstorming:
- `status` exported as the **raw** value (not localized) for spreadsheet filtering.
- Timestamp format `%Y-%m-%d %H:%M:%S` (vs. the UI's `%d.%m.%Y %H:%M`) for data analysis.
- **UTF-8 BOM** prepended for Excel compatibility.
