FactoryBot.define do
  factory :event, class: "OnboardOnRails::Event" do
    user_id { 1 }
    name { "first_project_created" }
    payload { {} }
  end
end
