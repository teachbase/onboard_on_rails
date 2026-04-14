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

    context "device type filtering" do
      it "returns tour with device_type 'all' for any device" do
        tour = create(:tour, url_pattern: ["/dashboard/*"], device_type: "all")
        create(:step, tour: tour)

        result = described_class.new(user: user, url: "/dashboard/home", device_type: "mobile").match
        expect(result).to eq(tour)
      end

      it "returns tour when device_type matches" do
        tour = create(:tour, :mobile_only, url_pattern: ["/dashboard/*"])
        create(:step, tour: tour)

        result = described_class.new(user: user, url: "/dashboard/home", device_type: "mobile").match
        expect(result).to eq(tour)
      end

      it "excludes tour when device_type does not match" do
        tour = create(:tour, :desktop_only, url_pattern: ["/dashboard/*"])
        create(:step, tour: tour)

        result = described_class.new(user: user, url: "/dashboard/home", device_type: "mobile").match
        expect(result).to be_nil
      end

      it "returns any tour when device_type param is blank" do
        tour = create(:tour, :mobile_only, url_pattern: ["/dashboard/*"])
        create(:step, tour: tour)

        result = described_class.new(user: user, url: "/dashboard/home").match
        expect(result).to eq(tour)
      end
    end

    context "in-progress tour resumption" do
      it "does not resume a desktop-only in-progress tour on mobile" do
        tour = create(:tour, :desktop_only, url_pattern: ["/dashboard/*"])
        step1 = create(:step, tour: tour, position: 1)
        step2 = create(:step, tour: tour, position: 2)
        create(:completion, tour: tour, user_id: user.id, step_id: step2.id, status: "in_progress")

        result = described_class.new(user: user, url: "/dashboard/home", device_type: "mobile").match
        expect(result).to be_nil
      end

      it "resumes an in-progress tour on a step's URL" do
        tour = create(:tour, url_pattern: ["/teacher/students"])
        step1 = create(:step, tour: tour, position: 1, url_pattern: nil)
        step2 = create(:step, tour: tour, position: 2, url_pattern: "/teacher/courses")
        create(:completion, tour: tour, user_id: user.id, step_id: step2.id, status: "in_progress")

        result = described_class.new(user: user, url: "/teacher/courses").match
        expect(result).to eq(tour)
      end

      it "returns current_step_index for resumed tour" do
        tour = create(:tour, url_pattern: ["/teacher/students"])
        step1 = create(:step, tour: tour, position: 1, url_pattern: nil)
        step2 = create(:step, tour: tour, position: 2, url_pattern: "/teacher/courses")
        create(:completion, tour: tour, user_id: user.id, step_id: step2.id, status: "in_progress")

        matcher = described_class.new(user: user, url: "/teacher/courses")
        matcher.match
        expect(matcher.current_step_index).to eq(1)
      end

      it "computes current_step_index 0 when no completion exists" do
        tour = create(:tour, url_pattern: ["/dashboard/*"])
        create(:step, tour: tour, position: 1)

        matcher = described_class.new(user: user, url: "/dashboard/home")
        matcher.match
        expect(matcher.current_step_index).to eq(0)
      end

      it "prioritizes in-progress tour over new tour match" do
        old_tour = create(:tour, url_pattern: ["/teacher/students"], priority: 1)
        step1 = create(:step, tour: old_tour, position: 1)
        step2 = create(:step, tour: old_tour, position: 2, url_pattern: "/shared-page")
        create(:completion, tour: old_tour, user_id: user.id, step_id: step2.id, status: "in_progress")

        new_tour = create(:tour, url_pattern: ["/shared-page"], priority: 100)
        create(:step, tour: new_tour, position: 1)

        result = described_class.new(user: user, url: "/shared-page").match
        expect(result).to eq(old_tour)
      end

      it "does not resume a completed tour" do
        tour = create(:tour, url_pattern: ["/teacher/students"], frequency: "once")
        step1 = create(:step, tour: tour, position: 1)
        create(:completion, tour: tour, user_id: user.id, step_id: step1.id, status: "completed")

        result = described_class.new(user: user, url: "/teacher/students").match
        expect(result).to be_nil
      end

      it "does not resume when step URL doesn't match current page" do
        tour = create(:tour, url_pattern: ["/teacher/students"])
        step1 = create(:step, tour: tour, position: 1)
        step2 = create(:step, tour: tour, position: 2, url_pattern: "/teacher/courses")
        create(:completion, tour: tour, user_id: user.id, step_id: step2.id, status: "in_progress")

        result = described_class.new(user: user, url: "/unrelated/page").match
        expect(result).to be_nil
      end

      it "resumes tour when current step has no url_pattern and tour URL matches" do
        tour = create(:tour, url_pattern: ["/dashboard/*"])
        step1 = create(:step, tour: tour, position: 1)
        step2 = create(:step, tour: tour, position: 2, url_pattern: nil)
        create(:completion, tour: tour, user_id: user.id, step_id: step2.id, status: "in_progress")

        result = described_class.new(user: user, url: "/dashboard/home").match
        expect(result).to eq(tour)
      end
    end
  end
end
