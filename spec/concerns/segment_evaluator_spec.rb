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
