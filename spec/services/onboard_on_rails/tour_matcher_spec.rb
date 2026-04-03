require "rails_helper"

RSpec.describe OnboardOnRails::TourMatcher do
  let(:user) { User.create!(email: "test@test.com", role: "admin", plan: "pro") }

  before do
    OnboardOnRails.configure do |config|
      config.user_attributes = ->(u) { { role: u.role, plan: u.plan, signed_up_at: u.created_at.to_s } }
    end
  end

  describe "#match" do
    it "returns the highest priority active tour matching the URL" do
      low = create(:tour, url_pattern: ["/dashboard/*"], priority: 1)
      high = create(:tour, url_pattern: ["/dashboard/*"], priority: 10)
      create(:step, tour: low)
      create(:step, tour: high)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to eq(high)
    end

    it "excludes draft and archived tours" do
      create(:tour, :draft, url_pattern: ["/dashboard/*"]).tap { |t| create(:step, tour: t) }
      create(:tour, :archived, url_pattern: ["/dashboard/*"]).tap { |t| create(:step, tour: t) }

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "excludes tours outside schedule window" do
      tour = create(:tour, url_pattern: ["/dashboard/*"],
        schedule_start: 2.days.from_now, schedule_end: 3.days.from_now)
      create(:step, tour: tour)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "excludes tours already completed when frequency is once" do
      tour = create(:tour, url_pattern: ["/dashboard/*"], frequency: "once")
      create(:step, tour: tour)
      create(:completion, tour: tour, user_id: user.id, status: "completed")

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "includes tours with frequency always even if completed" do
      tour = create(:tour, url_pattern: ["/dashboard/*"], frequency: "always")
      create(:step, tour: tour)
      create(:completion, tour: tour, user_id: user.id, status: "completed")

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to eq(tour)
    end

    it "excludes tours when segment rules don't match" do
      tour = create(:tour, url_pattern: ["/dashboard/*"], segment_rules: {
        "conditions" => [{ "attribute" => "role", "operator" => "eq", "value" => "user" }],
        "logic" => "and"
      })
      create(:step, tour: tour)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end

    it "filters by A/B test group" do
      tour_a = create(:tour, url_pattern: ["/dashboard/*"], ab_test_id: "exp1", ab_test_group: "A")
      tour_b = create(:tour, url_pattern: ["/dashboard/*"], ab_test_id: "exp1", ab_test_group: "B")
      create(:step, tour: tour_a)
      create(:step, tour: tour_b)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect([tour_a, tour_b]).to include(result)
    end

    it "handles event-triggered tours" do
      tour = create(:tour, :event_triggered, url_pattern: ["/dashboard/*"])
      create(:step, tour: tour)
      create(:event, user_id: user.id, name: "first_project_created")

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to eq(tour)
    end

    it "excludes event-triggered tours when event hasn't fired" do
      tour = create(:tour, :event_triggered, url_pattern: ["/dashboard/*"])
      create(:step, tour: tour)

      result = described_class.new(user: user, url: "/dashboard/home").match
      expect(result).to be_nil
    end
  end
end
