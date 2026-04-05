require "rails_helper"

RSpec.describe OnboardOnRails::TourCopier do
  describe ".call" do
    let(:original) do
      create(:tour,
        name: "Welcome Tour",
        description: "Intro",
        status: "active",
        trigger_type: "event",
        trigger_event: "signup",
        frequency: "once",
        theme: "modal",
        priority: 5,
        schedule_start: 1.day.ago,
        schedule_end: 1.day.from_now,
        ab_test_id: "exp1",
        ab_test_group: "A",
        url_pattern: ["/dashboard/*"],
        style_overrides: { "background_color" => "#fff" },
        segment_rules: { "logic" => "and", "conditions" => [{ "attribute" => "plan", "operator" => "eq", "value" => "pro" }] }
      )
    end

    let!(:step1) do
      create(:step, tour: original, position: 1, title: "Step One", body: "<p>Hello</p>",
        selector: "#header", placement: "top", action_type: "next", action_value: nil,
        wait_for_selector: ".loaded", url_pattern: "/page1",
        style_overrides: { "text_color" => "#000" })
    end

    let!(:step2) do
      create(:step, tour: original, position: 2, title: "Step Two", body: "<p>World</p>",
        selector: ".btn", placement: "bottom", action_type: "redirect", action_value: "/done",
        wait_for_selector: nil, url_pattern: nil,
        style_overrides: {})
    end

    let!(:completion) { create(:completion, tour: original, user_id: 1, status: "completed") }

    subject { described_class.call(original) }

    it "returns a persisted tour" do
      expect(subject).to be_persisted
    end

    it "sets name with copy suffix" do
      expect(subject.name).to eq("Welcome Tour #{I18n.t('onboard_on_rails.admin.tours.copy_suffix')}")
    end

    it "sets status to draft" do
      expect(subject.status).to eq("draft")
    end

    it "copies tour attributes" do
      expect(subject.description).to eq("Intro")
      expect(subject.trigger_type).to eq("event")
      expect(subject.trigger_event).to eq("signup")
      expect(subject.frequency).to eq("once")
      expect(subject.theme).to eq("modal")
      expect(subject.priority).to eq(5)
      expect(subject.schedule_start).to be_within(1.second).of(original.schedule_start)
      expect(subject.schedule_end).to be_within(1.second).of(original.schedule_end)
      expect(subject.ab_test_id).to eq("exp1")
      expect(subject.ab_test_group).to eq("A")
      expect(subject.url_pattern).to eq(["/dashboard/*"])
      expect(subject.style_overrides).to eq({ "background_color" => "#fff" })
      expect(subject.segment_rules).to eq({ "logic" => "and", "conditions" => [{ "attribute" => "plan", "operator" => "eq", "value" => "pro" }] })
    end

    it "copies all steps with correct attributes" do
      steps = subject.steps.order(:position)
      expect(steps.count).to eq(2)

      s1 = steps.first
      expect(s1.title).to eq("Step One")
      expect(s1.body).to eq("<p>Hello</p>")
      expect(s1.selector).to eq("#header")
      expect(s1.placement).to eq("top")
      expect(s1.action_type).to eq("next")
      expect(s1.action_value).to be_nil
      expect(s1.wait_for_selector).to eq(".loaded")
      expect(s1.url_pattern).to eq("/page1")
      expect(s1.style_overrides).to eq({ "text_color" => "#000" })
      expect(s1.position).to eq(1)

      s2 = steps.second
      expect(s2.title).to eq("Step Two")
      expect(s2.position).to eq(2)
      expect(s2.action_type).to eq("redirect")
      expect(s2.action_value).to eq("/done")
    end

    it "does not copy completions" do
      expect(subject.completions).to be_empty
    end

    it "creates a new tour record (not the original)" do
      expect(subject.id).not_to eq(original.id)
    end

    it "creates new step records (not the originals)" do
      subject.steps.each do |step|
        expect([step1.id, step2.id]).not_to include(step.id)
      end
    end

    context "when tour save fails" do
      it "returns an unpersisted tour and does not create steps" do
        # Force creation of original tour and steps before stubbing
        original; step1; step2
        step_count = OnboardOnRails::Step.count

        # Stub save! to raise only for new (unsaved) tour records
        allow_any_instance_of(OnboardOnRails::Tour).to receive(:save!) do |tour|
          raise ActiveRecord::RecordInvalid.new(tour) unless tour.id.present?
        end

        result = described_class.call(original)

        expect(result).not_to be_persisted
        expect(OnboardOnRails::Step.count).to eq(step_count)
      end
    end

    context "when step save fails after tour is saved" do
      it "rolls back and returns an unpersisted tour" do
        original; step1; step2
        tour_count = OnboardOnRails::Tour.count
        step_count = OnboardOnRails::Step.count

        # Stub save! on steps to raise for new (unsaved) step records
        allow_any_instance_of(OnboardOnRails::Step).to receive(:save!) do |step|
          raise ActiveRecord::RecordInvalid.new(step) unless step.id.present?
        end

        result = described_class.call(original)

        expect(result).not_to be_persisted
        expect(OnboardOnRails::Tour.count).to eq(tour_count)
        expect(OnboardOnRails::Step.count).to eq(step_count)
      end
    end
  end
end
