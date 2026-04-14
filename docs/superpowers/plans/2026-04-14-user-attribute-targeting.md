# User Attribute Targeting — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `user_attributes` lambda with a DSL-based `register_attribute` system that provides metadata for the admin UI, and extend segment_rules with new string/numeric operators.

**Architecture:** New `AttributeDefinition` value object + DSL on `Configuration`. `SegmentEvaluator` gets 7 new operators. Admin form gets segment_rules section powered by `data-available-attributes` JSON. Existing segment rules JS in `admin.js` is rewritten to use dynamic attributes.

**Tech Stack:** Ruby/Rails engine, vanilla JS, RSpec, FactoryBot

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `lib/onboard_on_rails/attribute_definition.rb` | Create | Value object: key, type, label, description, values, resolver |
| `lib/onboard_on_rails/configuration.rb` | Modify | Remove `user_attributes`, add `register_attribute` DSL, `resolve_attributes`, `attributes_schema` |
| `lib/onboard_on_rails.rb` | Modify | Require `attribute_definition` |
| `app/models/onboard_on_rails/concerns/segment_evaluator.rb` | Modify | Add 7 new operators, fix numeric comparison, normalize `in` |
| `app/services/onboard_on_rails/tour_matcher.rb` | Modify | Use `config.resolve_attributes(user)` instead of `config.user_attributes.call(user)` |
| `app/views/onboard_on_rails/admin/tours/_form.html.erb` | Modify | Add segment_rules section with data attributes |
| `app/assets/javascripts/onboard_on_rails/admin.js` | Modify | Rewrite segment rules controller: dynamic attributes, operators by type, descriptions |
| `app/assets/stylesheets/onboard_on_rails/admin.css` | Modify | Add styles for segment rules section |
| `app/controllers/onboard_on_rails/admin/tours_controller.rb` | Modify | Parse `segment_rules_json` in `tour_params` |
| `config/locales/en.yml` | Modify | Add segment_rules keys |
| `config/locales/ru.yml` | Modify | Add segment_rules keys |
| `spec/lib/configuration_spec.rb` | Modify | Tests for `register_attribute`, `resolve_attributes`, `attributes_schema` |
| `spec/concerns/segment_evaluator_spec.rb` | Modify | Tests for new operators |
| `spec/services/onboard_on_rails/tour_matcher_spec.rb` | Modify | Update `before` block to use `register_attribute` |
| `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb` | Modify | Test `segment_rules_json` param parsing |

---

### Task 1: AttributeDefinition + Configuration DSL

**Files:**
- Create: `lib/onboard_on_rails/attribute_definition.rb`
- Modify: `lib/onboard_on_rails/configuration.rb`
- Modify: `lib/onboard_on_rails.rb`
- Test: `spec/lib/configuration_spec.rb`

- [ ] **Step 1: Write failing tests for Configuration DSL**

In `spec/lib/configuration_spec.rb`, replace the entire file content:

```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Configuration do
  subject(:config) { described_class.new }

  describe "#user_locale" do
    it "defaults to a lambda returning 'ru'" do
      fake_user = double("User")
      expect(config.user_locale.call(fake_user)).to eq("ru")
    end

    it "can be overridden" do
      config.user_locale = ->(user) { user.lang }
      fake_user = double("User", lang: "en")
      expect(config.user_locale.call(fake_user)).to eq("en")
    end
  end

  describe "#register_attribute" do
    it "stores an attribute definition" do
      config.register_attribute(:email, type: :string, label: "Email") { |u| u.email }
      expect(config.registered_attributes).to have_key(:email)
    end

    it "stores all metadata" do
      config.register_attribute(:plan, type: :string, label: "Plan", description: "User plan", values: ["free", "pro"]) { |u| u.plan }
      attr_def = config.registered_attributes[:plan]
      expect(attr_def.key).to eq(:plan)
      expect(attr_def.type).to eq(:string)
      expect(attr_def.label).to eq("Plan")
      expect(attr_def.description).to eq("User plan")
      expect(attr_def.values).to eq(["free", "pro"])
    end

    it "raises if no block given" do
      expect {
        config.register_attribute(:email, type: :string, label: "Email")
      }.to raise_error(ArgumentError, /block required/i)
    end
  end

  describe "#resolve_attributes" do
    it "calls each resolver with the user and returns a hash" do
      fake_user = double("User", email: "foo@bar.com", role: "admin")
      config.register_attribute(:email, type: :string, label: "Email") { |u| u.email }
      config.register_attribute(:role, type: :string, label: "Role") { |u| u.role }

      result = config.resolve_attributes(fake_user)
      expect(result).to eq({ email: "foo@bar.com", role: "admin" })
    end

    it "returns empty hash when no attributes registered" do
      fake_user = double("User")
      expect(config.resolve_attributes(fake_user)).to eq({})
    end
  end

  describe "#attributes_schema" do
    it "returns an array of attribute metadata without resolvers" do
      config.register_attribute(:email, type: :string, label: "Email", description: "User email") { |u| u.email }
      config.register_attribute(:plan, type: :string, label: "Plan", values: ["free", "pro"]) { |u| u.plan }

      schema = config.attributes_schema
      expect(schema).to eq([
        { key: :email, type: :string, label: "Email", description: "User email", values: nil },
        { key: :plan, type: :string, label: "Plan", description: nil, values: ["free", "pro"] }
      ])
    end
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec spec/lib/configuration_spec.rb`
Expected: Multiple failures — `registered_attributes`, `register_attribute`, `resolve_attributes`, `attributes_schema` are not defined.

- [ ] **Step 3: Create AttributeDefinition**

Create `lib/onboard_on_rails/attribute_definition.rb`:

```ruby
module OnboardOnRails
  AttributeDefinition = Struct.new(:key, :type, :label, :description, :values, :resolver, keyword_init: true)
end
```

- [ ] **Step 4: Add require to lib/onboard_on_rails.rb**

In `lib/onboard_on_rails.rb`, add `require "onboard_on_rails/attribute_definition"` after the version require. The file should look like:

```ruby
require "onboard_on_rails/version"
require "onboard_on_rails/attribute_definition"
require "onboard_on_rails/configuration"
require "onboard_on_rails/engine"

module OnboardOnRails
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def track_event(user, name, payload = {})
      OnboardOnRails::Event.create!(
        user_id: user.id,
        name: name,
        payload: payload
      )
    end
  end
end
```

- [ ] **Step 5: Update Configuration class**

Replace the content of `lib/onboard_on_rails/configuration.rb`:

```ruby
module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :current_user_method, :user_locale
    attr_reader :registered_attributes

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @current_user_method = :current_user
      @user_locale = ->(user) { "ru" }
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
end
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec spec/lib/configuration_spec.rb`
Expected: All 7 examples pass.

- [ ] **Step 7: Commit**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add lib/onboard_on_rails/attribute_definition.rb lib/onboard_on_rails/configuration.rb lib/onboard_on_rails.rb spec/lib/configuration_spec.rb
git commit -m "feat: add register_attribute DSL to configuration"
```

---

### Task 2: Extend SegmentEvaluator with new operators

**Files:**
- Modify: `app/models/onboard_on_rails/concerns/segment_evaluator.rb`
- Test: `spec/concerns/segment_evaluator_spec.rb`

- [ ] **Step 1: Write failing tests for new operators**

Replace the content of `spec/concerns/segment_evaluator_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe OnboardOnRails::Concerns::SegmentEvaluator do
  describe "#matches_segment?" do
    let(:user_attributes) { { role: "admin", plan: "pro", email: "foo@example.com", name: "Alexander", account_id: 42, active: true } }

    it "returns true when segment_rules is empty" do
      tour = build(:tour, segment_rules: {})
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "returns true when conditions is empty array" do
      tour = build(:tour, segment_rules: { "conditions" => [], "logic" => "and" })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    context "equality operators" do
      it "matches eq" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "admin" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "rejects eq when value differs" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "user" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be false
      end

      it "matches not_eq" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "role", "operator" => "not_eq", "value" => "user" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end
    end

    context "in/not_in operators" do
      it "matches in with array value" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "plan", "operator" => "in", "value" => ["pro", "enterprise"] }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches in with comma-separated string value" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "plan", "operator" => "in", "value" => "pro, enterprise" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches not_in" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "plan", "operator" => "not_in", "value" => ["free", "trial"] }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches in for numeric attribute with comma-separated string" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "account_id", "operator" => "in", "value" => "42, 99, 100" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end
    end

    context "numeric comparison operators" do
      it "matches gt with numbers" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "account_id", "operator" => "gt", "value" => "10" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "rejects gt when value is smaller" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "account_id", "operator" => "gt", "value" => "100" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be false
      end

      it "matches lt" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "account_id", "operator" => "lt", "value" => "100" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches gte" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "account_id", "operator" => "gte", "value" => "42" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches lte" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "account_id", "operator" => "lte", "value" => "42" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end
    end

    context "string operators" do
      it "matches starts_with" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "email", "operator" => "starts_with", "value" => "foo" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "rejects starts_with when not matching" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "email", "operator" => "starts_with", "value" => "bar" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be false
      end

      it "matches ends_with" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "email", "operator" => "ends_with", "value" => "@example.com" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches contains" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "email", "operator" => "contains", "value" => "example" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches not_contains" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "email", "operator" => "not_contains", "value" => "gmail" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "matches matches (regex)" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "email", "operator" => "matches", "value" => "^foo@.*\\.com$" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "returns false for invalid regex in matches" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "email", "operator" => "matches", "value" => "[invalid" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be false
      end

      it "matches length_gt" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "name", "operator" => "length_gt", "value" => "5" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "rejects length_gt when name is shorter" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "name", "operator" => "length_gt", "value" => "20" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be false
      end

      it "matches length_lt" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "name", "operator" => "length_lt", "value" => "20" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end
    end

    context "logic" do
      it "handles AND — all conditions must match" do
        tour = build(:tour, segment_rules: {
          "conditions" => [
            { "attribute" => "role", "operator" => "eq", "value" => "admin" },
            { "attribute" => "plan", "operator" => "eq", "value" => "free" }
          ],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be false
      end

      it "handles OR — any condition can match" do
        tour = build(:tour, segment_rules: {
          "conditions" => [
            { "attribute" => "role", "operator" => "eq", "value" => "user" },
            { "attribute" => "plan", "operator" => "eq", "value" => "pro" }
          ],
          "logic" => "or"
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end

      it "defaults to AND when logic is not specified" do
        tour = build(:tour, segment_rules: {
          "conditions" => [
            { "attribute" => "role", "operator" => "eq", "value" => "admin" },
            { "attribute" => "plan", "operator" => "eq", "value" => "pro" }
          ]
        })
        expect(tour.matches_segment?(user_attributes)).to be true
      end
    end

    context "nil attribute" do
      it "returns false when attribute is nil" do
        tour = build(:tour, segment_rules: {
          "conditions" => [{ "attribute" => "missing", "operator" => "eq", "value" => "anything" }],
          "logic" => "and"
        })
        expect(tour.matches_segment?(user_attributes)).to be false
      end
    end
  end
end
```

- [ ] **Step 2: Run tests to verify new ones fail**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec spec/concerns/segment_evaluator_spec.rb`
Expected: Tests for `starts_with`, `ends_with`, `contains`, `not_contains`, `matches`, `length_gt`, `length_lt` fail. Tests for comma-separated `in` fail. Existing operator tests may fail too (numeric comparison change).

- [ ] **Step 3: Implement new SegmentEvaluator**

Replace the content of `app/models/onboard_on_rails/concerns/segment_evaluator.rb`:

```ruby
module OnboardOnRails
  module Concerns
    module SegmentEvaluator
      extend ActiveSupport::Concern

      def matches_segment?(user_attributes)
        rules = segment_rules
        return true if rules.blank? || rules["conditions"].blank?

        conditions = rules["conditions"]
        logic = rules.fetch("logic", "and")

        if logic == "or"
          conditions.any? { |c| evaluate_condition(c, user_attributes) }
        else
          conditions.all? { |c| evaluate_condition(c, user_attributes) }
        end
      end

      private

      def evaluate_condition(condition, user_attributes)
        attr_name = condition["attribute"]
        operator = condition["operator"]
        expected = condition["value"]
        actual = user_attributes[attr_name.to_sym]

        return false if actual.nil?

        case operator
        when "eq"           then actual.to_s == expected.to_s
        when "not_eq"       then actual.to_s != expected.to_s
        when "in"           then normalize_list(expected).include?(actual.to_s)
        when "not_in"       then !normalize_list(expected).include?(actual.to_s)
        when "gt"           then actual.to_f > expected.to_f
        when "lt"           then actual.to_f < expected.to_f
        when "gte"          then actual.to_f >= expected.to_f
        when "lte"          then actual.to_f <= expected.to_f
        when "starts_with"  then actual.to_s.start_with?(expected.to_s)
        when "ends_with"    then actual.to_s.end_with?(expected.to_s)
        when "contains"     then actual.to_s.include?(expected.to_s)
        when "not_contains" then !actual.to_s.include?(expected.to_s)
        when "matches"      then actual.to_s.match?(Regexp.new(expected.to_s)) rescue false
        when "length_gt"    then actual.to_s.length > expected.to_i
        when "length_lt"    then actual.to_s.length < expected.to_i
        else false
        end
      end

      def normalize_list(value)
        case value
        when Array then value.map { |v| v.to_s.strip }
        when String then value.split(",").map(&:strip)
        else [value.to_s]
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec spec/concerns/segment_evaluator_spec.rb`
Expected: All examples pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add app/models/onboard_on_rails/concerns/segment_evaluator.rb spec/concerns/segment_evaluator_spec.rb
git commit -m "feat: add string operators and numeric comparison to segment evaluator"
```

---

### Task 3: Update TourMatcher to use resolve_attributes

**Files:**
- Modify: `app/services/onboard_on_rails/tour_matcher.rb`
- Test: `spec/services/onboard_on_rails/tour_matcher_spec.rb`

- [ ] **Step 1: Update the TourMatcher spec before block**

In `spec/services/onboard_on_rails/tour_matcher_spec.rb`, replace lines 4-9 (the `let` and `before` block):

```ruby
  let(:user) { User.create!(email: "test@test.com", role: "admin", plan: "pro") }

  before do
    OnboardOnRails.configure do |config|
      config.register_attribute(:role, type: :string, label: "Role") { |u| u.role }
      config.register_attribute(:plan, type: :string, label: "Plan") { |u| u.plan }
      config.register_attribute(:signed_up_at, type: :string, label: "Signed up") { |u| u.created_at.to_s }
    end
  end
```

- [ ] **Step 2: Run TourMatcher spec to verify it fails**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec spec/services/onboard_on_rails/tour_matcher_spec.rb`
Expected: Failures because `TourMatcher` still calls `config.user_attributes.call(user)` which no longer exists.

- [ ] **Step 3: Update TourMatcher**

In `app/services/onboard_on_rails/tour_matcher.rb`, replace line 10:

Old:
```ruby
      @user_attributes = OnboardOnRails.configuration.user_attributes.call(user)
```

New:
```ruby
      @user_attributes = OnboardOnRails.configuration.resolve_attributes(user)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec spec/services/onboard_on_rails/tour_matcher_spec.rb`
Expected: All examples pass.

- [ ] **Step 5: Run full test suite to check nothing else broke**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec`
Expected: All pass. If any specs fail because they reference `config.user_attributes`, fix those too.

- [ ] **Step 6: Commit**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add app/services/onboard_on_rails/tour_matcher.rb spec/services/onboard_on_rails/tour_matcher_spec.rb
git commit -m "feat: use resolve_attributes in TourMatcher"
```

---

### Task 4: Localization — add segment_rules keys

**Files:**
- Modify: `config/locales/en.yml`
- Modify: `config/locales/ru.yml`

- [ ] **Step 1: Add English locale keys**

In `config/locales/en.yml`, add the following block inside `onboard_on_rails:` at the same level as `flash:`, `statuses:`, etc. (after the `action_types:` block, at the end of the file):

```yaml
    segment_rules:
      title: "User Targeting"
      description_hint: "Configure conditions to target specific users"
      add_condition: "Add condition"
      remove_condition: "Remove"
      no_attributes: "No targetable attributes configured. Add register_attribute to your OnboardOnRails initializer."
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
        value: "value"
        boolean_true: "true"
        boolean_false: "false"
```

- [ ] **Step 2: Add Russian locale keys**

In `config/locales/ru.yml`, add the following block inside `onboard_on_rails:` at the same level as `flash:`, `statuses:`, etc. (after the `action_types:` block, at the end of the file):

```yaml
    segment_rules:
      title: "Таргетинг по пользователям"
      description_hint: "Настройте условия для показа тура определённым пользователям"
      add_condition: "Добавить условие"
      remove_condition: "Удалить"
      no_attributes: "Нет настроенных атрибутов. Добавьте register_attribute в инициализатор OnboardOnRails."
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
        value: "значение"
        boolean_true: "да"
        boolean_false: "нет"
```

- [ ] **Step 3: Commit**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add config/locales/en.yml config/locales/ru.yml
git commit -m "feat: add segment_rules locale keys (en/ru)"
```

---

### Task 5: Admin form — segment_rules section

**Files:**
- Modify: `app/views/onboard_on_rails/admin/tours/_form.html.erb`
- Modify: `app/controllers/onboard_on_rails/admin/tours_controller.rb`
- Test: `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb`

- [ ] **Step 1: Add segment_rules section to the form**

In `app/views/onboard_on_rails/admin/tours/_form.html.erb`, add the following block **before** the `<h4>` style_overrides heading (before line 89 `<h4 class="oor-mb-sm"`):

```erb
  <% attributes_schema = OnboardOnRails.configuration.attributes_schema %>
  <% if attributes_schema.any? %>
    <div class="oor-segment-rules-section" data-controller="segment-rules"
         data-available-attributes="<%= attributes_schema.to_json %>"
         data-operator-labels="<%= t('onboard_on_rails.segment_rules.operators').to_json %>"
         data-placeholders="<%= t('onboard_on_rails.segment_rules.placeholders').to_json %>">

      <h4 class="oor-mb-sm" style="margin-top: 20px;"><%= t("onboard_on_rails.segment_rules.title") %></h4>
      <p class="oor-form-hint" style="margin-bottom: 12px;"><%= t("onboard_on_rails.segment_rules.description_hint") %></p>

      <div class="oor-form-group">
        <label><%= t("onboard_on_rails.segment_rules.logic.and").split("(").first.strip %></label>
        <select data-segment-rules-target="logic" class="oor-form-control" style="width: auto;">
          <option value="and"><%= t("onboard_on_rails.segment_rules.logic.and") %></option>
          <option value="or"><%= t("onboard_on_rails.segment_rules.logic.or") %></option>
        </select>
      </div>

      <div data-segment-rules-target="container"></div>

      <button type="button" class="oor-btn oor-btn--sm oor-btn--secondary" data-action="segment-rules#add" style="margin-bottom: 16px;">
        + <%= t("onboard_on_rails.segment_rules.add_condition") %>
      </button>

      <input type="hidden" name="tour[segment_rules_json]" data-segment-rules-target="output" value="<%= tour.segment_rules.to_json %>">
    </div>
  <% else %>
    <p class="oor-form-hint" style="margin-top: 20px;"><%= t("onboard_on_rails.segment_rules.no_attributes") %></p>
  <% end %>
```

- [ ] **Step 2: Update tour_params to parse segment_rules_json**

In `app/controllers/onboard_on_rails/admin/tours_controller.rb`, replace the `tour_params` method (lines 60-77):

```ruby
      def tour_params
        permitted = params.require(:tour).permit(
          :name, :description, :status, :trigger_type, :trigger_event,
          :frequency, :theme, :priority, :schedule_start, :schedule_end,
          :ab_test_id, :ab_test_group, :device_type,
          style_overrides: {}
        )

        if params[:tour].key?(:url_pattern)
          if params[:tour][:url_pattern].is_a?(String)
            permitted[:url_pattern] = params[:tour][:url_pattern].split(",").map(&:strip).reject(&:blank?)
          else
            permitted[:url_pattern] = params[:tour].permit(url_pattern: [])[:url_pattern] || []
          end
        end

        if params[:tour][:segment_rules_json].present?
          permitted[:segment_rules] = JSON.parse(params[:tour][:segment_rules_json])
        end

        permitted
      end
```

Note: `segment_rules: {}` is removed from the `permit` call since we now parse it from `segment_rules_json`.

- [ ] **Step 3: Write test for segment_rules_json parsing**

In `spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb`, add the following test inside the top-level `describe` block (after the existing `describe "POST #copy"` block):

```ruby
  describe "PATCH #update with segment_rules_json" do
    it "parses segment_rules_json into segment_rules" do
      tour = create(:tour, name: "Test")
      rules = { "conditions" => [{ "attribute" => "email", "operator" => "starts_with", "value" => "foo" }], "logic" => "and" }

      patch :update, params: { id: tour.id, tour: { segment_rules_json: rules.to_json } }

      tour.reload
      expect(tour.segment_rules["conditions"].first["operator"]).to eq("starts_with")
      expect(tour.segment_rules["logic"]).to eq("and")
    end
  end
```

- [ ] **Step 4: Run controller spec**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add app/views/onboard_on_rails/admin/tours/_form.html.erb app/controllers/onboard_on_rails/admin/tours_controller.rb spec/controllers/onboard_on_rails/admin/tours_controller_spec.rb
git commit -m "feat: add segment_rules section to tour form with JSON parsing"
```

---

### Task 6: Rewrite segment rules JS with dynamic attributes

**Files:**
- Modify: `app/assets/javascripts/onboard_on_rails/admin.js`

- [ ] **Step 1: Rewrite the Segment Rules Controller section**

In `app/assets/javascripts/onboard_on_rails/admin.js`, replace lines 45-115 (the entire `// === Segment Rules Controller ===` section) with:

```javascript
// === Segment Rules Controller ===
document.addEventListener("DOMContentLoaded", function() {
  var wrapper = document.querySelector("[data-controller='segment-rules']");
  if (!wrapper) return;

  var container = wrapper.querySelector("[data-segment-rules-target='container']");
  var output = wrapper.querySelector("[data-segment-rules-target='output']");
  var logicSelect = wrapper.querySelector("[data-segment-rules-target='logic']");
  var addButton = wrapper.querySelector("[data-action*='segment-rules#add']");

  var availableAttributes = [];
  var operatorLabels = {};
  var placeholders = {};

  try { availableAttributes = JSON.parse(wrapper.getAttribute("data-available-attributes") || "[]"); } catch(e) {}
  try { operatorLabels = JSON.parse(wrapper.getAttribute("data-operator-labels") || "{}"); } catch(e) {}
  try { placeholders = JSON.parse(wrapper.getAttribute("data-placeholders") || "{}"); } catch(e) {}

  var OPERATORS_BY_TYPE = {
    string:  ["eq", "not_eq", "in", "not_in", "starts_with", "ends_with", "contains", "not_contains", "matches", "length_gt", "length_lt"],
    number:  ["eq", "not_eq", "in", "not_in", "gt", "lt", "gte", "lte"],
    boolean: ["eq"]
  };

  function findAttr(key) {
    for (var i = 0; i < availableAttributes.length; i++) {
      if (availableAttributes[i].key === key) return availableAttributes[i];
    }
    return null;
  }

  function serialize() {
    var rows = container.querySelectorAll(".oor-segment-row");
    var conditions = Array.from(rows).map(function(row) {
      var op = row.querySelector(".oor-segment-op").value;
      var val = row.querySelector(".oor-segment-val").value;
      if (op === "in" || op === "not_in") {
        val = val.split(",").map(function(v) { return v.trim(); });
      }
      return {
        attribute: row.querySelector(".oor-segment-attr").value,
        operator: op,
        value: val
      };
    });
    var logic = logicSelect ? logicSelect.value : "and";
    output.value = JSON.stringify({ conditions: conditions, logic: logic });
  }

  function buildAttrSelect(selectedKey) {
    var html = "";
    for (var i = 0; i < availableAttributes.length; i++) {
      var a = availableAttributes[i];
      var sel = a.key === selectedKey ? " selected" : "";
      html += '<option value="' + a.key + '"' + sel + '>' + a.label + '</option>';
    }
    return html;
  }

  function buildOpSelect(type, selectedOp) {
    var ops = OPERATORS_BY_TYPE[type] || OPERATORS_BY_TYPE.string;
    var html = "";
    for (var i = 0; i < ops.length; i++) {
      var op = ops[i];
      var label = operatorLabels[op] || op;
      var sel = op === selectedOp ? " selected" : "";
      html += '<option value="' + op + '"' + sel + '>' + label + '</option>';
    }
    return html;
  }

  function buildValueInput(attrDef, operator, value) {
    if (operator === "eq" && attrDef && attrDef.type === "boolean") {
      return '<select class="oor-segment-val oor-form-control" style="flex:1;">' +
        '<option value="true"' + (value === "true" ? " selected" : "") + '>true</option>' +
        '<option value="false"' + (value !== "true" ? " selected" : "") + '>false</option>' +
        '</select>';
    }
    if ((operator === "eq" || operator === "not_eq") && attrDef && attrDef.values && attrDef.values.length > 0) {
      var html = '<select class="oor-segment-val oor-form-control" style="flex:1;">';
      for (var i = 0; i < attrDef.values.length; i++) {
        var v = attrDef.values[i];
        var sel = v === value ? " selected" : "";
        html += '<option value="' + v + '"' + sel + '>' + v + '</option>';
      }
      html += '</select>';
      return html;
    }
    var placeholder = placeholders.value || "value";
    if (operator === "in" || operator === "not_in") placeholder = placeholders.in_values || "values separated by comma";
    if (operator === "matches") placeholder = placeholders.regex || "regular expression";
    var displayValue = Array.isArray(value) ? value.join(", ") : (value || "");
    return '<input type="text" placeholder="' + placeholder + '" value="' + displayValue + '" class="oor-segment-val oor-form-control" style="flex:1;">';
  }

  function addConditionRow(condition) {
    var attrKey = condition.attribute || (availableAttributes[0] ? availableAttributes[0].key : "");
    var attrDef = findAttr(attrKey);
    var type = attrDef ? attrDef.type : "string";
    var operator = condition.operator || "eq";

    var row = document.createElement("div");
    row.className = "oor-segment-row";

    row.innerHTML =
      '<div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap;">' +
        '<select class="oor-segment-attr oor-form-control" style="flex:1;min-width:120px;">' + buildAttrSelect(attrKey) + '</select>' +
        '<select class="oor-segment-op oor-form-control" style="flex:1;min-width:120px;">' + buildOpSelect(type, operator) + '</select>' +
        buildValueInput(attrDef, operator, Array.isArray(condition.value) ? condition.value.join(", ") : (condition.value || "")) +
        '<button type="button" class="oor-segment-remove oor-btn oor-btn--sm oor-btn--danger" style="flex-shrink:0;">&times;</button>' +
      '</div>' +
      (attrDef && attrDef.description ? '<div class="oor-segment-description">' + attrDef.description + '</div>' : '');

    // Remove button
    row.querySelector(".oor-segment-remove").addEventListener("click", function() {
      row.remove();
      serialize();
    });

    // Attribute change -> rebuild operators + value + description
    var attrSelect = row.querySelector(".oor-segment-attr");
    attrSelect.addEventListener("change", function() {
      var newAttrDef = findAttr(attrSelect.value);
      var newType = newAttrDef ? newAttrDef.type : "string";
      var opSelect = row.querySelector(".oor-segment-op");
      opSelect.innerHTML = buildOpSelect(newType, "eq");
      // Rebuild value
      var oldValEl = row.querySelector(".oor-segment-val");
      var temp = document.createElement("div");
      temp.innerHTML = buildValueInput(newAttrDef, "eq", "");
      oldValEl.parentNode.replaceChild(temp.firstChild, oldValEl);
      // Update description
      var descEl = row.querySelector(".oor-segment-description");
      if (descEl) descEl.remove();
      if (newAttrDef && newAttrDef.description) {
        var newDesc = document.createElement("div");
        newDesc.className = "oor-segment-description";
        newDesc.textContent = newAttrDef.description;
        row.appendChild(newDesc);
      }
      bindRowEvents(row);
      serialize();
    });

    // Operator change -> rebuild value input
    var opSelect = row.querySelector(".oor-segment-op");
    opSelect.addEventListener("change", function() {
      var currentAttrDef = findAttr(attrSelect.value);
      var oldValEl = row.querySelector(".oor-segment-val");
      var temp = document.createElement("div");
      temp.innerHTML = buildValueInput(currentAttrDef, opSelect.value, "");
      oldValEl.parentNode.replaceChild(temp.firstChild, oldValEl);
      bindRowEvents(row);
      serialize();
    });

    bindRowEvents(row);
    container.appendChild(row);
    serialize();
  }

  function bindRowEvents(row) {
    row.querySelectorAll(".oor-segment-val, .oor-segment-op, .oor-segment-attr").forEach(function(el) {
      el.removeEventListener("change", serialize);
      el.removeEventListener("input", serialize);
      el.addEventListener("change", serialize);
      el.addEventListener("input", serialize);
    });
  }

  function loadExisting() {
    var data;
    try { data = JSON.parse(output.value || "{}"); } catch(e) { data = {}; }
    if (data.conditions && data.conditions.length > 0) {
      data.conditions.forEach(function(c) { addConditionRow(c); });
    }
    if (data.logic && logicSelect) logicSelect.value = data.logic;
  }

  if (addButton) {
    addButton.addEventListener("click", function(e) {
      e.preventDefault();
      addConditionRow({ attribute: "", operator: "eq", value: "" });
    });
  }

  if (logicSelect) {
    logicSelect.addEventListener("change", serialize);
  }

  loadExisting();
});
```

- [ ] **Step 2: Commit**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add app/assets/javascripts/onboard_on_rails/admin.js
git commit -m "feat: rewrite segment rules JS with dynamic attributes and operators"
```

---

### Task 7: Admin CSS for segment rules

**Files:**
- Modify: `app/assets/stylesheets/onboard_on_rails/admin.css`

- [ ] **Step 1: Add CSS for segment rules section**

Append the following block at the end of `app/assets/stylesheets/onboard_on_rails/admin.css`:

```css
/* ============================================
   Segment Rules
   ============================================ */
.oor-segment-rules-section {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid var(--oor-border);
}

.oor-segment-row {
  margin-bottom: 10px;
}

.oor-segment-row:last-child {
  margin-bottom: 0;
}

.oor-segment-description {
  font-size: 12px;
  color: var(--oor-text-light);
  margin-top: 4px;
  margin-left: 2px;
  margin-bottom: 8px;
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add app/assets/stylesheets/onboard_on_rails/admin.css
git commit -m "feat: add segment rules admin styles"
```

---

### Task 8: Final verification

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston && bundle exec rspec`
Expected: All specs pass.

- [ ] **Step 2: Fix any remaining failures**

If any spec still references `config.user_attributes`, update it to use `register_attribute` DSL. Common places to check:
- `spec/controllers/onboard_on_rails/api/tours_controller_spec.rb`
- Any other spec with `config.user_attributes = ...`

Search for references: `grep -r "user_attributes" spec/`

- [ ] **Step 3: Final commit if fixes were needed**

```bash
cd /Users/aleksandrsvajkin/conductor/workspaces/onboard_on_rails/kingston
git add -A
git commit -m "fix: update remaining specs to use register_attribute DSL"
```
