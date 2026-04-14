require "rails_helper"

RSpec.describe OnboardOnRails::Tour, type: :model do
  describe "validations" do
    it "requires a name" do
      tour = build(:tour, name: nil)
      expect(tour).not_to be_valid
      expect(tour.errors[:name]).to include("can't be blank")
    end

    it "validates status inclusion" do
      tour = build(:tour, status: "invalid")
      expect(tour).not_to be_valid
    end

    it "validates trigger_type inclusion" do
      tour = build(:tour, trigger_type: "invalid")
      expect(tour).not_to be_valid
    end

    it "validates frequency inclusion" do
      tour = build(:tour, frequency: "invalid")
      expect(tour).not_to be_valid
    end

    it "validates theme inclusion" do
      tour = build(:tour, theme: "invalid")
      expect(tour).not_to be_valid
    end

    it "requires trigger_event when trigger_type is event" do
      tour = build(:tour, trigger_type: "event", trigger_event: nil)
      expect(tour).not_to be_valid
      expect(tour.errors[:trigger_event]).to include("can't be blank")
    end

    it "validates device_type inclusion" do
      tour = build(:tour, device_type: "invalid")
      expect(tour).not_to be_valid
    end

    it "defaults device_type to all" do
      tour = build(:tour)
      expect(tour.device_type).to eq("all")
    end

    it "defaults overlay_enabled to true" do
      tour = build(:tour)
      expect(tour.overlay_enabled).to eq(true)
    end

    it "is valid with all required attributes" do
      tour = build(:tour)
      expect(tour).to be_valid
    end
  end

  describe "scopes" do
    it ".active returns only active tours" do
      active = create(:tour, status: "active")
      create(:tour, :draft)
      create(:tour, :archived)

      expect(described_class.active).to eq([active])
    end

    it ".scheduled_now returns tours within schedule window" do
      in_window = create(:tour, :with_schedule)
      past = create(:tour, schedule_start: 3.days.ago, schedule_end: 2.days.ago)
      future = create(:tour, schedule_start: 2.days.from_now, schedule_end: 3.days.from_now)
      no_schedule = create(:tour, schedule_start: nil, schedule_end: nil)

      result = described_class.scheduled_now
      expect(result).to include(in_window, no_schedule)
      expect(result).not_to include(past, future)
    end

    it ".by_priority orders by priority descending" do
      low = create(:tour, priority: 1)
      high = create(:tour, priority: 10)
      mid = create(:tour, priority: 5)

      expect(described_class.by_priority).to eq([high, mid, low])
    end
  end

  describe "associations" do
    it "has many steps ordered by position" do
      tour = create(:tour)
      step2 = create(:step, tour: tour, position: 2)
      step1 = create(:step, tour: tour, position: 1)

      expect(tour.steps).to eq([step1, step2])
    end

    it "has many completions" do
      tour = create(:tour)
      completion = create(:completion, tour: tour)

      expect(tour.completions).to eq([completion])
    end

    it "destroys steps when destroyed" do
      tour = create(:tour)
      create(:step, tour: tour)

      expect { tour.destroy }.to change(OnboardOnRails::Step, :count).by(-1)
    end
  end
end
