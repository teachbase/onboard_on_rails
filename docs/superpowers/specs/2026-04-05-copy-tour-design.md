# Copy Tour Feature — Design Spec

## Overview

Add the ability to duplicate a tour with all its steps from the admin panel. A "Copy" button on the tour index page creates a draft copy and redirects to its edit page.

## Service: `OnboardOnRails::TourCopier`

**File:** `app/services/onboard_on_rails/tour_copier.rb`

**Interface:** `TourCopier.call(tour)` — returns the new (saved) tour, or an unsaved tour with errors.

**Behavior:**

1. Wrap everything in `ActiveRecord::Base.transaction`.
2. `tour.dup` to copy all tour attributes.
3. Set `name` to `"#{original.name} #{I18n.t('onboard_on_rails.admin.tours.copy_suffix')}"` — suffix is locale-aware: "(copy)" in en, "(копия)" in ru.
4. Set `status` to `"draft"`.
5. All other fields copied as-is: description, trigger_type, trigger_event, frequency, theme, priority, schedule_start, schedule_end, ab_test_id, ab_test_group, url_pattern, style_overrides, segment_rules.
6. Save the new tour.
7. For each original step (ordered by `position`): `step.dup`, assign to new tour, save. Copied fields: title, selector, placement, action_type, position, url_pattern, style_overrides.
8. Completions are **not** copied.
9. If any save fails, the transaction rolls back and the tour object is returned with errors.

## Route

```ruby
# config/routes.rb — inside namespace :admin
resources :tours do
  post :copy, on: :member
  # existing nested resources...
end
```

Generates: `POST /admin/tours/:id/copy` -> `Admin::ToursController#copy`

## Controller Action

**File:** `app/controllers/onboard_on_rails/admin/tours_controller.rb`

```ruby
def copy
  original = Tour.find(params[:id])
  copied = TourCopier.call(original)

  if copied.persisted?
    redirect_to edit_admin_tour_path(copied),
                notice: t(".success")
  else
    redirect_to admin_tours_path,
                alert: t(".failure")
  end
end
```

## View: Copy Button

**File:** `app/views/onboard_on_rails/admin/tours/_tour.html.erb`

Add `button_to` between Edit and Delete in the actions column:

```erb
<%= button_to t(".copy"), copy_admin_tour_path(tour), method: :post, class: "..." %>
```

## Locales

### en.yml

```yaml
onboard_on_rails:
  admin:
    tours:
      copy_suffix: "(copy)"
      tour:
        copy: "Copy"
      copy:
        success: "Tour copied successfully"
        failure: "Failed to copy tour"
```

### ru.yml

```yaml
onboard_on_rails:
  admin:
    tours:
      copy_suffix: "(копия)"
      tour:
        copy: "Копировать"
      copy:
        success: "Тур успешно скопирован"
        failure: "Не удалось скопировать тур"
```

## Tests

### Service spec: `spec/services/onboard_on_rails/tour_copier_spec.rb`

- Copies all tour attributes (description, trigger_type, frequency, theme, priority, etc.)
- Sets name to `"#{original.name} (копия)"`
- Sets status to `"draft"`
- Copies all steps with correct attributes and position order
- Does not copy completions
- Wraps in transaction — rolls back on step save failure
- Returns persisted tour on success, unpersisted tour with errors on failure

### Controller spec: `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb`

- `POST #copy` creates a new tour
- Redirects to edit page of the new tour
- Sets flash notice on success
- Redirects to index with flash alert on failure
