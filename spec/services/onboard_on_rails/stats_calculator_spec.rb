require "rails_helper"

RSpec.describe OnboardOnRails::StatsCalculator do
  let(:tour) { create(:tour) }
  let!(:step1) { create(:step, tour: tour, position: 1) }
  let!(:step2) { create(:step, tour: tour, position: 2) }
  let!(:step3) { create(:step, tour: tour, position: 3) }

  describe "#summary" do
    it "calculates completion rate" do
      create(:completion, tour: tour, user_id: 1, status: "completed")
      create(:completion, tour: tour, user_id: 2, status: "completed")
      create(:completion, tour: tour, user_id: 3, status: "dismissed")
      create(:completion, tour: tour, user_id: 4, status: "in_progress")

      stats = described_class.new(tour).summary
      expect(stats[:total_started]).to eq(4)
      expect(stats[:completed]).to eq(2)
      expect(stats[:dismissed]).to eq(1)
      expect(stats[:completion_rate]).to eq(50.0)
    end

    it "handles zero completions" do
      stats = described_class.new(tour).summary
      expect(stats[:total_started]).to eq(0)
      expect(stats[:completion_rate]).to eq(0)
    end
  end
end
