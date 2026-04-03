require "rails_helper"

RSpec.describe OnboardOnRails::Step, type: :model do
  describe "validations" do
    it "requires a title" do
      step = build(:step, title: nil)
      expect(step).not_to be_valid
    end

    it "requires a selector" do
      step = build(:step, selector: nil)
      expect(step).not_to be_valid
    end

    it "validates placement inclusion" do
      step = build(:step, placement: "diagonal")
      expect(step).not_to be_valid
    end

    it "validates action_type inclusion" do
      step = build(:step, action_type: "invalid")
      expect(step).not_to be_valid
    end

    it "is valid with all required attributes" do
      step = build(:step)
      expect(step).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a tour" do
      step = create(:step)
      expect(step.tour).to be_a(OnboardOnRails::Tour)
    end
  end
end
