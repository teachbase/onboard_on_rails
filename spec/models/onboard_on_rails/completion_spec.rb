require "rails_helper"

RSpec.describe OnboardOnRails::Completion, type: :model do
  describe "validations" do
    it "requires a user_id" do
      completion = build(:completion, user_id: nil)
      expect(completion).not_to be_valid
    end

    it "validates status inclusion" do
      completion = build(:completion, status: "invalid")
      expect(completion).not_to be_valid
    end

    it "is valid with required attributes" do
      completion = build(:completion)
      expect(completion).to be_valid
    end
  end

  describe "scopes" do
    it ".for_user returns completions for a specific user" do
      c1 = create(:completion, user_id: 1)
      create(:completion, user_id: 2)

      expect(described_class.for_user(1)).to eq([c1])
    end

    it ".completed returns only completed" do
      completed = create(:completion, status: "completed")
      create(:completion, status: "in_progress")

      expect(described_class.completed).to eq([completed])
    end
  end
end
