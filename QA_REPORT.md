## QA Test Report - OnboardOnRails Admin Panel
**Date:** 2026-04-03
**Tester:** Automated QA via Chrome DevTools
**App URL:** http://localhost:3000

---

### PASSED
- **Test 1: Tours List Page** -- Page loads with Russian text, tours table shows existing tours, status filters (Все/Черновик/Активный/В архиве) all work correctly, empty state shows "Туры не найдены" with CTA. No console errors.
- **Test 3: Create New Tour** -- Tour created with all fields. Flash message "Тур создан." shown, redirected to edit page. Name, description, status, theme, priority all saved correctly.
- **Test 4: Add Steps to Tour** -- Both steps created successfully with correct titles, bodies, selectors, placements. Position auto-increments. Flash "Шаг создан." shown. Live preview renders server-side on page load.
- **Test 5: Edit Step - Live Preview** -- Server-rendered preview displays correctly with mock page layout, target element highlighting (dashed border), tooltip with title/body/buttons.
- **Test 7: Selector Picker** -- Picker page loads with toolbar (SELECTOR input, Confirm, Cancel buttons) and iframe showing host app. Functional.
- **Test 8: Tour Statistics** -- Stats page shows Начато/Завершено/Пропущено/Процент завершения metrics. Drop-off table shows per-step data with ПОЗИЦИЯ/ШАГ/ОТКАЗЫ columns.
- **Test 9: Tour Player on Dashboard** -- Tour overlay appears on /dashboard. API GET /onboard/api/tours returns 200 with full tour+steps JSON. Next/Back/Skip/Done buttons all functional. Completion tracked via POST /onboard/api/completions (201). Frequency "once" prevents re-showing after completion. Next tour in priority queue serves correctly.
- **Test 10: Console & Network Errors** -- Zero JavaScript console errors. Zero 4xx/5xx network errors across all pages.

### FAILED
- **Test 2: Delete Tour** -- Clicking "Удалить" does NOT delete the tour. Instead it navigates to the tour edit page via GET. The confirm dialog never appears. **Root cause:** The delete link uses `data-method="delete"` and `data-confirm="..."` (Rails UJS attributes), but neither Rails UJS nor Turbo is loaded in the admin JS bundle. The link falls back to a regular GET request which hits the `show` action (which redirects to `edit`).
- **Test 6: Edit Step - Style Overrides (Live Update)** -- Changing style override values (background color, button color) does NOT update the live preview in real time. **Root cause:** The Stimulus framework is not loaded (`typeof Stimulus === 'undefined'`). The `step_preview_controller.js` requires a global `Stimulus` object which is absent. **Partial pass:** Style overrides DO save correctly to the database and the server-rendered preview reflects them after page reload.

---

### BUGS FOUND

#### Bug 1: Delete functionality completely broken (CRITICAL)
- **Description:** "Удалить" (Delete) buttons on tours list and step list do not work. They perform a GET instead of DELETE request.
- **Steps to reproduce:** Go to /onboard/admin, click "Удалить" on any tour.
- **Expected:** Confirm dialog appears, tour is deleted, flash message shown.
- **Actual:** Navigates to /onboard/admin/tours/:id which redirects to edit page. No deletion occurs.
- **Root cause:** `data-method="delete"` requires Rails UJS or Turbo, neither of which is loaded in the admin JS bundle (`admin.debug-*.js`).
- **Fix:** Either include `@rails/ujs` in the admin JS bundle, switch to Turbo, or convert delete links to `button_to` forms (which use POST with `_method=delete` hidden field and don't require JS).
- **Severity:** CRITICAL -- admins cannot delete any tours or steps.

#### Bug 2: URL pattern not saved (MAJOR)
- **Description:** The URL pattern field on the tour form does not persist its value.
- **Steps to reproduce:** Create/edit a tour, enter "/dashboard, /dashboard/*" in URL паттерн field, submit.
- **Expected:** URL pattern saved as `["/dashboard", "/dashboard/*"]`.
- **Actual:** Saved as empty array `[]`. Field is blank on next page load.
- **Root cause:** The form sends `tour[url_pattern]` as a plain string, but the controller strong params expects `url_pattern: []` (array). The string is rejected by Rails permit, so it defaults to empty.
- **Fix:** Add a `before_action` or model callback to split the comma-separated string into an array, or change the form to use multiple hidden inputs for array values.
- **Severity:** MAJOR -- URL-based tour targeting is completely non-functional.

#### Bug 3: Stimulus not loaded in admin panel (MAJOR)
- **Description:** The Stimulus JS framework is not loaded, so all Stimulus controllers (including step preview live update) are non-functional.
- **Steps to reproduce:** Open browser console on any admin page, type `typeof Stimulus`.
- **Expected:** `"function"` or `"object"`.
- **Actual:** `"undefined"`.
- **Root cause:** The admin JS bundle does not include or import Stimulus. The `step_preview_controller.js` checks `if (typeof Stimulus === "undefined") return;` and silently exits.
- **Fix:** Include Stimulus in the admin JS bundle (e.g., via importmap or direct script tag for `@hotwired/stimulus`).
- **Severity:** MAJOR -- live preview updates don't work, any future Stimulus-dependent features will also be broken.

#### Bug 4: Step delete also broken (same as Bug 1) (CRITICAL)
- **Description:** Same issue as Bug 1 but for step deletion on the tour edit page.
- **Affected view:** `app/views/onboard_on_rails/admin/tours/edit.html.erb` line 32.
- **Severity:** CRITICAL.

---

### WARNINGS

1. **Selector picker link missing parameters:** The "Выбрать" link on the step edit form points to `/onboard/selector_picker` without `tour_id` or `step_id` query params. It should include context so the selected value can be sent back. Additionally, the link should use `target="_blank"` since it opens a separate tool.

2. **Preview placement mismatch:** When placement is set to "Сверху" (Top), the server-rendered preview still renders the tooltip below the target element. The preview does not accurately reflect the placement setting.

3. **Step-level style overrides not applied in player:** The tour player tooltip on the dashboard did not apply step-level style overrides (e.g., background_color #ff6b6b was not rendered). The API sends the overrides, but the client-side renderer may not be reading them.

4. **Tour buttons in English:** The tour player buttons show "Skip", "Next", "Back", "Done" in English while the admin UI is fully in Russian. Consider localizing the player buttons.

5. **URL ПАТТЕРН column always empty in tours table:** Since URL patterns never save (Bug 2), this column is blank for all tours, reducing the usefulness of the list view.

---

### Test Environment
- Browser: Chrome 146
- OS: macOS (Darwin 25.3.0)
- Rails app: localhost:3000 (development mode)
- Locale: ru (Russian)
