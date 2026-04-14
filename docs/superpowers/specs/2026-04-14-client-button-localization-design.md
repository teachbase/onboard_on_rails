# Client Button Localization

## Summary

Localize the 4 system button texts in tour steps (Skip, Back, Next, Done) based on the user's language setting in the host application. Default language is Russian; any language other than Russian falls back to English.

## Motivation

Currently button labels are hardcoded in English in `client.js:364-366`. Users of Russian-language applications see English buttons in an otherwise Russian-localized interface.

## Design

### Configuration

Add `user_locale` lambda to `OnboardOnRails::Configuration`:

```ruby
attr_accessor :user_locale

def initialize
  # ... existing defaults ...
  @user_locale = ->(user) { "ru" }
end
```

Host app configures:

```ruby
OnboardOnRails.configure do |config|
  config.user_locale = ->(user) { user.lang || "ru" }
end
```

### Meta Tag

`MetaTagsHelper#onboard_on_rails_meta_tags` renders locale meta tag:

```ruby
locale = OnboardOnRails.configuration.user_locale.call(user)
tag.meta(name: "onboard-on-rails-locale", content: locale)
```

### Client JS — I18n Module

New `OnboardOnRails.I18n` module in `client.js`:

```js
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

Locale resolution: if the locale from the meta tag exists in the translations dictionary, use it; otherwise fall back to `"en"`.

### Button Rendering

Replace hardcoded strings in `client.js` tour renderer (lines 364-366):

```js
<button class="oor-btn-skip" data-action="dismiss">${OnboardOnRails.I18n.t('skip')}</button>
${!isFirst ? `<button class="oor-btn-prev" data-action="prev">${OnboardOnRails.I18n.t('back')}</button>` : ''}
<button class="oor-btn-next" data-action="${isLast ? 'complete' : 'next'}">${isLast ? OnboardOnRails.I18n.t('done') : OnboardOnRails.I18n.t('next')}</button>
```

## Files to Modify

1. `lib/onboard_on_rails/configuration.rb` — add `user_locale` attr with default lambda
2. `app/helpers/onboard_on_rails/meta_tags_helper.rb` — render locale meta tag
3. `app/assets/javascripts/onboard_on_rails/client.js` — add I18n module, replace hardcoded button texts

## Supported Languages

| Locale | Skip | Back | Next | Done |
|--------|------|------|------|------|
| `ru` | Пропустить | Назад | Далее | Готово |
| `en` (fallback) | Skip | Back | Next | Done |

## Testing

- Unit test for `MetaTagsHelper` — verify locale meta tag is rendered
- JS: verify `I18n.t()` returns correct text for `ru` and `en`
- JS: verify unknown locale falls back to `en`
