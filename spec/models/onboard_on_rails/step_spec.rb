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

  describe "#matches_step_url?" do
    it "returns true when url_pattern is blank" do
      step = build(:step, url_pattern: nil)
      expect(step.matches_step_url?("/anything")).to be true
    end

    it "returns true when url_pattern is empty string" do
      step = build(:step, url_pattern: "")
      expect(step.matches_step_url?("/anything")).to be true
    end

    it "matches exact URL" do
      step = build(:step, url_pattern: "/teacher/courses")
      expect(step.matches_step_url?("/teacher/courses")).to be true
      expect(step.matches_step_url?("/teacher/students")).to be false
    end

    it "matches glob with single wildcard" do
      step = build(:step, url_pattern: "/users/*/about")
      expect(step.matches_step_url?("/users/42/about")).to be true
      expect(step.matches_step_url?("/users/42/edit")).to be false
    end

    it "matches glob with double wildcard" do
      step = build(:step, url_pattern: "/admin/**")
      expect(step.matches_step_url?("/admin/tours/1/steps")).to be true
      expect(step.matches_step_url?("/admin")).to be false
    end

    it "matches regex pattern (with backslash)" do
      step = build(:step, url_pattern: '/users/\d+/profile')
      expect(step.matches_step_url?("/users/123/profile")).to be true
      expect(step.matches_step_url?("/users/abc/profile")).to be false
    end
  end
end
