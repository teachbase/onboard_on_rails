FactoryBot.define do
  factory :completion, class: "OnboardOnRails::Completion" do
    tour
    user_id { 1 }
    status { "in_progress" }
    started_at { Time.current }
    session_id { SecureRandom.hex(16) }
  end
end
