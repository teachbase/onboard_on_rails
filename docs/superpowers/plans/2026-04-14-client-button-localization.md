# Client Button Localization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Localize tour step buttons (Skip, Back, Next, Done) based on the user's language, with Russian as default and English as fallback.

**Architecture:** Add a `user_locale` config lambda → render locale via meta tag → JS I18n module reads it and provides translations for button text.

**Tech Stack:** Ruby (Rails engine configuration + helper), vanilla JS (I18n module)

---

### Task 1: Add `user_locale` to Configuration

**Files:**
- Modify: `lib/onboard_on_rails/configuration.rb:3-10`
- Test: `spec/lib/configuration_spec.rb` (create)

- [ ] **Step 1: Write the failing test**

Create `spec/lib/configuration_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Configuration do
  describe "#user_locale" do
    it "defaults to a lambda returning 'ru'" do
      config = described_class.new
      fake_user = double("User")
      expect(config.user_locale.call(fake_user)).to eq("ru")
    end

    it "can be overridden" do
      config = described_class.new
      config.user_locale = ->(user) { user.lang }
      fake_user = double("User", lang: "en")
      expect(config.user_locale.call(fake_user)).to eq("en")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/lib/configuration_spec.rb -v`
Expected: FAIL — `user_locale` method not found

- [ ] **Step 3: Add `user_locale` to Configuration**

In `lib/onboard_on_rails/configuration.rb`, add `user_locale` to `attr_accessor` and set the default in `initialize`:

```ruby
module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :user_attributes, :current_user_method, :user_locale

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @user_attributes = ->(user) { {} }
      @current_user_method = :current_user
      @user_locale = ->(user) { "ru" }
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/lib/configuration_spec.rb -v`
Expected: 2 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add lib/onboard_on_rails/configuration.rb spec/lib/configuration_spec.rb
git commit -m "feat: add user_locale config option with Russian default"
```

---

### Task 2: Render locale meta tag

**Files:**
- Modify: `app/helpers/onboard_on_rails/meta_tags_helper.rb:3-13`
- Test: `spec/helpers/meta_tags_helper_spec.rb` (create)

- [ ] **Step 1: Write the failing test**

Create `spec/helpers/meta_tags_helper_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::MetaTagsHelper, type: :helper do
  let(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    OnboardOnRails.configuration.current_user_method = :current_user
  end

  describe "#onboard_on_rails_meta_tags" do
    it "includes locale meta tag with default 'ru'" do
      result = helper.onboard_on_rails_meta_tags
      expect(result).to include('name="onboard-on-rails-locale"')
      expect(result).to include('content="ru"')
    end

    it "uses configured user_locale lambda" do
      allow(user).to receive(:lang).and_return("en")
      OnboardOnRails.configuration.user_locale = ->(u) { u.lang }

      result = helper.onboard_on_rails_meta_tags
      expect(result).to include('content="en"')
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/helpers/meta_tags_helper_spec.rb -v`
Expected: FAIL — no locale meta tag in output

- [ ] **Step 3: Add locale meta tag to helper**

In `app/helpers/onboard_on_rails/meta_tags_helper.rb`:

```ruby
module OnboardOnRails
  module MetaTagsHelper
    def onboard_on_rails_meta_tags
      user = send(OnboardOnRails.configuration.current_user_method)
      return "" unless user

      mount_path = OnboardOnRails::Engine.routes.find_script_name({})
      mount_path = "/onboard" if mount_path.blank?

      locale = OnboardOnRails.configuration.user_locale.call(user)

      tag.meta(name: "onboard-on-rails-user-id", content: user.id) +
        tag.meta(name: "onboard-on-rails-mount-path", content: mount_path) +
        tag.meta(name: "csrf-token", content: form_authenticity_token) +
        tag.meta(name: "onboard-on-rails-locale", content: locale)
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/helpers/meta_tags_helper_spec.rb -v`
Expected: 2 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add app/helpers/onboard_on_rails/meta_tags_helper.rb spec/helpers/meta_tags_helper_spec.rb
git commit -m "feat: render locale meta tag from user_locale config"
```

---

### Task 3: Add I18n module and localize buttons in client.js

**Files:**
- Modify: `app/assets/javascripts/onboard_on_rails/client.js:4` (add I18n module after line 4), `client.js:364-366` (replace hardcoded button texts)

- [ ] **Step 1: Add I18n module to client.js**

Insert after line 4 (`window.OnboardOnRails = window.OnboardOnRails || {};`), before the `// === ApiClient ===` comment:

```js
// === I18n ===
OnboardOnRails.I18n = {
  translations: {
    ru: { skip: "Пропустить", back: "Назад", next: "Далее", done: "Готово" },
    en: { skip: "Skip", back: "Back", next: "Next", done: "Done" }
  },
  getLocale() {
    const meta = document.querySelector('meta[name="onboard-on-rails-locale"]');
    const locale = meta ? meta.content : "ru";
    return this.translations[locale] ? locale : "en";
  },
  t(key) {
    return this.translations[this.getLocale()][key];
  }
};

```

- [ ] **Step 2: Replace hardcoded button texts**

In the `createTooltip` method, replace the button HTML (the 3 lines inside `oor-step-actions` div):

Old:
```js
          <button class="oor-btn-skip" data-action="dismiss">Skip</button>
          ${!isFirst ? '<button class="oor-btn-prev" data-action="prev">Back</button>' : ''}
          <button class="oor-btn-next" data-action="${isLast ? 'complete' : 'next'}">${isLast ? 'Done' : 'Next'}</button>
```

New:
```js
          <button class="oor-btn-skip" data-action="dismiss">${OnboardOnRails.I18n.t('skip')}</button>
          ${!isFirst ? `<button class="oor-btn-prev" data-action="prev">${OnboardOnRails.I18n.t('back')}</button>` : ''}
          <button class="oor-btn-next" data-action="${isLast ? 'complete' : 'next'}">${isLast ? OnboardOnRails.I18n.t('done') : OnboardOnRails.I18n.t('next')}</button>
```

- [ ] **Step 3: Verify manually in dummy app**

Run: `cd spec/dummy && RAILS_ENV=development bin/rails server`
Visit `http://localhost:3000/onboard/admin`, create/view a tour. Buttons should show Russian text by default.

- [ ] **Step 4: Run full test suite**

Run: `bundle exec rspec`
Expected: all existing tests pass (no regressions)

- [ ] **Step 5: Commit**

```bash
git add app/assets/javascripts/onboard_on_rails/client.js
git commit -m "feat: localize tour step buttons (ru default, en fallback)"
```
