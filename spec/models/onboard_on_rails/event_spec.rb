require "rails_helper"

RSpec.describe OnboardOnRails::Event, type: :model do
  describe "validations" do
    it "requires a user_id" do
      event = build(:event, user_id: nil)
      expect(event).not_to be_valid
    end

    it "requires a name" do
      event = build(:event, name: nil)
      expect(event).not_to be_valid
    end

    it "is valid with required attributes" do
      event = build(:event)
      expect(event).to be_valid
    end
  end

  describe "scopes" do
    it ".for_user returns events for a specific user" do
      e1 = create(:event, user_id: 1)
      create(:event, user_id: 2)

      expect(described_class.for_user(1)).to eq([e1])
    end

    it ".by_name returns events with specific name" do
      match = create(:event, name: "signup")
      create(:event, name: "purchase")

      expect(described_class.by_name("signup")).to eq([match])
    end
  end
end
