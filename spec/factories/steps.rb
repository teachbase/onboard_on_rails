FactoryBot.define do
  factory :step, class: "OnboardOnRails::Step" do
    tour
    sequence(:position) { |n| n }
    title { "Step title" }
    body { "Step body text" }
    selector { "#main-header" }
    placement { "bottom" }
    action_type { "next" }
  end
end
