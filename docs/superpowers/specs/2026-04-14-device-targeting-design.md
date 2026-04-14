# Device Type Targeting for Tours

## Summary

Add the ability to target tours by device type (desktop, mobile, or all devices). Device type is determined client-side by screen width and acts as an AND condition with all other targeting criteria.

## Design Decisions

- **Detection**: Client-side via `window.innerWidth`
- **Breakpoint**: `< 768px` = mobile, `>= 768px` = desktop
- **Storage**: Dedicated `device_type` string column on `onboard_on_rails_tours` table
- **Values**: `all` (default), `desktop`, `mobile`
- **Logic**: AND with existing targeting (URL pattern, segment rules, frequency, A/B tests)

## Changes

### 1. Migration

Add `device_type` column to `onboard_on_rails_tours`:

```ruby
add_column :onboard_on_rails_tours, :device_type, :string, default: "all", null: false
```

### 2. Tour Model (`app/models/onboard_on_rails/tour.rb`)

Add validation:

```ruby
validates :device_type, inclusion: { in: %w[all desktop mobile] }
```

### 3. Client — API Client (`app/assets/javascripts/onboard_on_rails/client/api_client.js`)

Add `device_type` parameter to the `GET /api/tours` request:

```javascript
var deviceType = window.innerWidth < 768 ? "mobile" : "desktop";
// append &device_type=mobile|desktop to the request URL
```

### 4. API Tours Controller (`app/controllers/onboard_on_rails/api/tours_controller.rb`)

Pass `device_type` param through to `TourMatcher`:

```ruby
TourMatcher.new(current_user, url: params[:url], session_id: params[:session_id], device_type: params[:device_type])
```

### 5. TourMatcher (`app/services/onboard_on_rails/tour_matcher.rb`)

Add device type filtering in the matching chain. A tour matches if its `device_type` is `"all"` or equals the provided device type:

```ruby
def matches_device?(tour)
  return true if tour.device_type == "all"
  return true if @device_type.blank?
  tour.device_type == @device_type
end
```

This check runs as AND alongside existing checks (URL, segment, frequency, event, A/B).

### 6. Admin Form (`app/views/onboard_on_rails/admin/tours/_form.html.erb`)

Add a select field in the targeting section:

```erb
<%= f.select :device_type, [
  [t(".device_type_all"), "all"],
  [t(".device_type_desktop"), "desktop"],
  [t(".device_type_mobile"), "mobile"]
] %>
```

### 7. Admin Tours Controller (`app/controllers/onboard_on_rails/admin/tours_controller.rb`)

Add `:device_type` to permitted params in `tour_params`.

### 8. Locales

Add translations for the select labels in `en.yml` and `ru.yml`:

- `device_type_all`: "All devices" / "Все устройства"
- `device_type_desktop`: "Desktop" / "Десктоп"
- `device_type_mobile`: "Mobile" / "Мобильные устройства"

### 9. Tests

- **Tour model**: validate `device_type` inclusion
- **TourMatcher**: tours with `device_type: "desktop"` only match when `device_type` param is `"desktop"`, `"all"` matches any device, blank param matches any tour
- **API tours controller**: verify `device_type` param is forwarded and filtering works end-to-end
