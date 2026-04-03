FactoryBot.define do
  factory :tour, class: "OnboardOnRails::Tour" do
    sequence(:name) { |n| "Tour #{n}" }
    description { "A test tour" }
    status { "active" }
    trigger_type { "auto" }
    url_pattern { ["/dashboard/*"] }
    frequency { "once" }
    theme { "tooltip" }
    priority { 0 }

    trait :draft do
      status { "draft" }
    end

    trait :archived do
      status { "archived" }
    end

    trait :event_triggered do
      trigger_type { "event" }
      trigger_event { "first_project_created" }
    end

    trait :with_schedule do
      schedule_start { 1.day.ago }
      schedule_end { 1.day.from_now }
    end

    trait :with_ab_test do
      ab_test_id { "experiment_1" }
      ab_test_group { "A" }
    end
  end
end
