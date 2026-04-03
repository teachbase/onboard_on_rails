require "rails_helper"

RSpec.describe OnboardOnRails::AbAssigner do
  describe ".assign_group" do
    it "returns nil when tour has no ab_test_id" do
      tour = build(:tour, ab_test_id: nil)
      expect(described_class.assign_group(user_id: 1, tour: tour)).to be_nil
    end

    it "returns a consistent group for the same user + experiment" do
      tour_a = build(:tour, ab_test_id: "exp1", ab_test_group: "A")
      tour_b = build(:tour, ab_test_id: "exp1", ab_test_group: "B")

      group1 = described_class.assign_group(user_id: 42, tour: tour_a, groups: %w[A B])
      group2 = described_class.assign_group(user_id: 42, tour: tour_b, groups: %w[A B])

      expect(group1).to eq(group2)
    end

    it "distributes users roughly evenly across groups" do
      counts = Hash.new(0)
      1000.times do |i|
        tour = build(:tour, ab_test_id: "exp1")
        group = described_class.assign_group(user_id: i, tour: tour, groups: %w[A B])
        counts[group] += 1
      end

      expect(counts["A"]).to be_between(400, 600)
      expect(counts["B"]).to be_between(400, 600)
    end
  end
end
