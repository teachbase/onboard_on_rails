require "rails_helper"

RSpec.describe OnboardOnRails::Concerns::SegmentEvaluator do
  describe "#matches_segment?" do
    let(:user_attributes) { { role: "admin", plan: "pro", signed_up_at: "2026-01-15" } }

    it "returns true when segment_rules is empty" do
      tour = build(:tour, segment_rules: {})
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "matches equality condition" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "admin" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "rejects when equality fails" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "user" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be false
    end

    it "matches not_eq operator" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "not_eq", "value" => "user" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "matches in operator" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "plan", "operator" => "in", "value" => ["pro", "enterprise"] }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "matches gt operator for dates" do
      tour = build(:tour, segment_rules: {
        "conditions" => [{ "attribute" => "signed_up_at", "operator" => "gt", "value" => "2026-01-01" }],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end

    it "handles AND logic — all conditions must match" do
      tour = build(:tour, segment_rules: {
        "conditions" => [
          { "attribute" => "role", "operator" => "eq", "value" => "admin" },
          { "attribute" => "plan", "operator" => "eq", "value" => "free" }
        ],
        "logic" => "and"
      })
      expect(tour.matches_segment?(user_attributes)).to be false
    end

    it "handles OR logic — any condition can match" do
      tour = build(:tour, segment_rules: {
        "conditions" => [
          { "attribute" => "role", "operator" => "eq", "value" => "user" },
          { "attribute" => "plan", "operator" => "eq", "value" => "pro" }
        ],
        "logic" => "or"
      })
      expect(tour.matches_segment?(user_attributes)).to be true
    end
  end
end
