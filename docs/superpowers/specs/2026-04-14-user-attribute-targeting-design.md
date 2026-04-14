# User Attribute Targeting — Design Spec

## Overview

Расширение системы таргетинга туров: DSL для регистрации пользовательских атрибутов с метаданными, расширенные операторы сравнения, и полноценный UI в админке для настройки segment_rules.

## 1. Configuration DSL

### Замена `user_attributes`

Удаляется `config.user_attributes`. Вместо него — `register_attribute` DSL.

### API

```ruby
OnboardOnRails.configure do |config|
  config.register_attribute :email, type: :string, label: "Email", description: "Email пользователя" do |user|
    user.email
  end

  config.register_attribute :account_id, type: :number, label: "Account ID", description: "ID аккаунта" do |user|
    user.account_id
  end

  config.register_attribute :plan, type: :string, label: "Тариф", description: "Тарифный план", values: ["free", "pro", "enterprise"] do |user|
    user.plan
  end

  config.register_attribute :admin, type: :boolean, label: "Админ?", description: "Является ли администратором" do |user|
    user.admin?
  end
end
```

### Параметры `register_attribute`

| Параметр | Обязательный | Описание |
|---|---|---|
| `key` | да | Символ-идентификатор (первый аргумент) |
| `type` | да | `:string`, `:number`, `:boolean` |
| `label` | да | Отображаемое название в админке |
| `description` | нет | Подсказка для админа |
| `values` | нет | Массив допустимых значений (для select в UI) |
| `block` | да | Лямбда `(user) -> value` для извлечения значения |

### Хранение в Configuration

```ruby
class Configuration
  attr_reader :registered_attributes

  def initialize
    @registered_attributes = {}
  end

  def register_attribute(key, type:, label:, description: nil, values: nil, &block)
    raise ArgumentError, "Block required for attribute #{key}" unless block_given?
    @registered_attributes[key] = AttributeDefinition.new(
      key: key, type: type, label: label, description: description, values: values, resolver: block
    )
  end

  def resolve_attributes(user)
    registered_attributes.each_with_object({}) do |(key, attr_def), hash|
      hash[key] = attr_def.resolver.call(user)
    end
  end

  def attributes_schema
    registered_attributes.values.map do |attr_def|
      { key: attr_def.key, type: attr_def.type, label: attr_def.label,
        description: attr_def.description, values: attr_def.values }
    end
  end
end
```

### AttributeDefinition

Простой value-object (Struct или Data class):

```ruby
AttributeDefinition = Struct.new(:key, :type, :label, :description, :values, :resolver, keyword_init: true)
```

Расположение: `lib/onboard_on_rails/attribute_definition.rb`.

## 2. Расширение SegmentEvaluator

### Новые операторы

| Оператор | Типы | Логика |
|---|---|---|
| `starts_with` | string | `value.to_s.start_with?(condition_value)` |
| `ends_with` | string | `value.to_s.end_with?(condition_value)` |
| `contains` | string | `value.to_s.include?(condition_value)` |
| `not_contains` | string | `!value.to_s.include?(condition_value)` |
| `matches` | string | `value.to_s.match?(Regexp.new(condition_value))` |
| `length_gt` | string | `value.to_s.length > condition_value.to_i` |
| `length_lt` | string | `value.to_s.length < condition_value.to_i` |

### Изменения существующих операторов

- `gt`, `lt`, `gte`, `lte`: числовое сравнение (`to_f`) вместо строкового.
- `in`, `not_in`: если `condition_value` — строка, сплитить по запятой и тримить. Работают для всех типов.

### Реализация

```ruby
module SegmentEvaluator
  def matches_segment?(user_attributes)
    return true if segment_rules.blank? || segment_rules["conditions"].blank?

    conditions = segment_rules["conditions"]
    logic = segment_rules["logic"] || "and"

    results = conditions.map { |c| evaluate_condition(c, user_attributes) }

    logic == "and" ? results.all? : results.any?
  end

  private

  def evaluate_condition(condition, user_attributes)
    attr_value = user_attributes[condition["attribute"].to_sym]
    operator = condition["operator"]
    condition_value = condition["value"]

    case operator
    when "eq"         then attr_value.to_s == condition_value.to_s
    when "not_eq"     then attr_value.to_s != condition_value.to_s
    when "in"         then normalize_list(condition_value).include?(attr_value.to_s)
    when "not_in"     then !normalize_list(condition_value).include?(attr_value.to_s)
    when "gt"         then attr_value.to_f > condition_value.to_f
    when "lt"         then attr_value.to_f < condition_value.to_f
    when "gte"        then attr_value.to_f >= condition_value.to_f
    when "lte"        then attr_value.to_f <= condition_value.to_f
    when "starts_with"  then attr_value.to_s.start_with?(condition_value.to_s)
    when "ends_with"    then attr_value.to_s.end_with?(condition_value.to_s)
    when "contains"     then attr_value.to_s.include?(condition_value.to_s)
    when "not_contains" then !attr_value.to_s.include?(condition_value.to_s)
    when "matches"      then attr_value.to_s.match?(Regexp.new(condition_value.to_s)) rescue false
    when "length_gt"    then attr_value.to_s.length > condition_value.to_i
    when "length_lt"    then attr_value.to_s.length < condition_value.to_i
    else false
    end
  end

  def normalize_list(value)
    case value
    when Array then value.map(&:to_s).map(&:strip)
    when String then value.split(",").map(&:strip)
    else [value.to_s]
    end
  end
end
```

## 3. Изменения в TourMatcher

Одно изменение — способ получения атрибутов:

```ruby
# Было:
@user_attributes = OnboardOnRails.configuration.user_attributes.call(@user)

# Стало:
@user_attributes = OnboardOnRails.configuration.resolve_attributes(@user)
```

Всё остальное (URL-matching, frequency, device_type, A/B) без изменений.

## 4. Admin UI — Segment Rules

### Data-атрибут

В `app/views/onboard_on_rails/admin/tours/_form.html.erb` добавляется новая секция:

```erb
<div class="form-section" id="segment-rules-section"
     data-available-attributes="<%= OnboardOnRails.configuration.attributes_schema.to_json %>"
     data-operators-labels="<%= t('onboard_on_rails.segment_rules.operators').to_json %>">

  <h3><%= t('onboard_on_rails.segment_rules.title') %></h3>
  <p class="hint"><%= t('onboard_on_rails.segment_rules.description_hint') %></p>

  <!-- Logic selector: AND / OR -->
  <div class="segment-logic">
    <label>
      <input type="radio" data-segment-logic value="and" checked>
      <%= t('onboard_on_rails.segment_rules.logic.and') %>
    </label>
    <label>
      <input type="radio" data-segment-logic value="or">
      <%= t('onboard_on_rails.segment_rules.logic.or') %>
    </label>
  </div>

  <!-- Conditions container -->
  <div id="segment-conditions"></div>

  <button type="button" id="add-segment-condition" class="btn btn-sm">
    + <%= t('onboard_on_rails.segment_rules.add_condition') %>
  </button>

  <!-- Hidden field for JSON -->
  <%= hidden_field_tag "tour[segment_rules_json]", @tour.segment_rules.to_json, id: "segment-rules-json" %>
</div>
```

### JavaScript: `admin/segment_rules_controller.js`

Новый файл. Логика:

1. При загрузке — парсит `data-available-attributes` и `data-operators-labels`.
2. Если тур уже имеет `segment_rules` — рендерит существующие условия.
3. Кнопка "Добавить условие" — добавляет строку: `[select атрибут] [select оператор] [input/select значение] [кнопка удалить]`.
4. При смене атрибута — обновляет список операторов по типу атрибута, показывает description.
5. При смене оператора на `in`/`not_in` — меняет placeholder на "значения через запятую".
6. При смене оператора на `eq` для boolean — меняет input на select true/false.
7. Если у атрибута есть `values` и оператор `eq`/`not_eq` — input заменяется на select с предзаданными значениями.
8. Перед submit формы — собирает все условия + логику в JSON и записывает в hidden field `segment_rules_json`.

### Маппинг операторов по типу

```javascript
const OPERATORS_BY_TYPE = {
  string:  ["eq", "not_eq", "in", "not_in", "starts_with", "ends_with", "contains", "not_contains", "matches", "length_gt", "length_lt"],
  number:  ["eq", "not_eq", "in", "not_in", "gt", "lt", "gte", "lte"],
  boolean: ["eq"]
};
```

### Строка условия (HTML-структура)

```
[Select: атрибут ▾]  [Select: оператор ▾]  [Input: значение]  [✕]
 ↳ мелкий текст: description атрибута
```

## 5. Контроллер — обработка segment_rules_json

В `Admin::ToursController#tour_params` добавить парсинг:

```ruby
def tour_params
  params.require(:tour).permit(...).tap do |p|
    if params[:tour][:segment_rules_json].present?
      p[:segment_rules] = JSON.parse(params[:tour][:segment_rules_json])
    end
  end
end
```

## 6. Локализация

### en.yml

```yaml
onboard_on_rails:
  segment_rules:
    title: "User Targeting"
    description_hint: "Configure conditions to target specific users"
    add_condition: "Add condition"
    remove_condition: "Remove"
    logic:
      and: "All conditions must match (AND)"
      or: "Any condition must match (OR)"
    operators:
      eq: "equals"
      not_eq: "does not equal"
      in: "is one of"
      not_in: "is not one of"
      gt: "greater than"
      lt: "less than"
      gte: "greater or equal"
      lte: "less or equal"
      starts_with: "starts with"
      ends_with: "ends with"
      contains: "contains"
      not_contains: "does not contain"
      matches: "matches regex"
      length_gt: "length greater than"
      length_lt: "length less than"
    placeholders:
      in_values: "values separated by comma"
      regex: "regular expression"
```

### ru.yml

```yaml
onboard_on_rails:
  segment_rules:
    title: "Таргетинг по пользователям"
    description_hint: "Настройте условия для показа тура определённым пользователям"
    add_condition: "Добавить условие"
    remove_condition: "Удалить"
    logic:
      and: "Все условия должны совпасть (И)"
      or: "Любое условие должно совпасть (ИЛИ)"
    operators:
      eq: "равно"
      not_eq: "не равно"
      in: "одно из"
      not_in: "не одно из"
      gt: "больше"
      lt: "меньше"
      gte: "больше или равно"
      lte: "меньше или равно"
      starts_with: "начинается с"
      ends_with: "заканчивается на"
      contains: "содержит"
      not_contains: "не содержит"
      matches: "соответствует regex"
      length_gt: "длина больше"
      length_lt: "длина меньше"
    placeholders:
      in_values: "значения через запятую"
      regex: "регулярное выражение"
```

## 7. Затрагиваемые файлы

| Файл | Действие |
|---|---|
| `lib/onboard_on_rails/configuration.rb` | Удалить `user_attributes`, добавить `register_attribute`, `resolve_attributes`, `attributes_schema` |
| `lib/onboard_on_rails/attribute_definition.rb` | Новый файл — Struct |
| `lib/onboard_on_rails.rb` | Require `attribute_definition`, удалить упоминания `user_attributes` |
| `app/models/onboard_on_rails/concerns/segment_evaluator.rb` | Добавить 7 операторов, исправить числовое сравнение, нормализация `in` |
| `app/services/onboard_on_rails/tour_matcher.rb` | `resolve_attributes` вместо `user_attributes.call` |
| `app/views/onboard_on_rails/admin/tours/_form.html.erb` | Добавить секцию segment_rules |
| `app/assets/javascripts/onboard_on_rails/admin/segment_rules_controller.js` | Новый файл — UI логика |
| `app/assets/stylesheets/onboard_on_rails/admin.css` | Стили для секции segment_rules |
| `app/controllers/onboard_on_rails/admin/tours_controller.rb` | Парсинг `segment_rules_json` |
| `config/locales/en.yml` | Добавить ключи segment_rules |
| `config/locales/ru.yml` | Добавить ключи segment_rules |
| `spec/dummy/config/initializers/onboard_on_rails.rb` | Обновить на DSL-стиль |
| `spec/concerns/segment_evaluator_spec.rb` | Тесты новых операторов |
| `spec/services/tour_matcher_spec.rb` | Обновить на `resolve_attributes` |

## 8. Вне скоупа

- Вложенные группы условий (AND внутри OR)
- Валидация segment_rules JSON на уровне модели
- Предпросмотр "кому покажется тур" в админке
