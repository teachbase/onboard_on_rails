require "rails_helper"

RSpec.describe OnboardOnRails::Concerns::UrlMatchable do
  describe "#matches_url?" do
    it "matches exact URL" do
      tour = build(:tour, url_pattern: ["/dashboard"])
      expect(tour.matches_url?("/dashboard")).to be true
    end

    it "matches glob with wildcard" do
      tour = build(:tour, url_pattern: ["/dashboard/*"])
      expect(tour.matches_url?("/dashboard/stats")).to be true
      expect(tour.matches_url?("/settings")).to be false
    end

    it "matches double wildcard for nested paths" do
      tour = build(:tour, url_pattern: ["/projects/**"])
      expect(tour.matches_url?("/projects/1/edit")).to be true
      expect(tour.matches_url?("/projects")).to be false
    end

    it "matches any of multiple patterns" do
      tour = build(:tour, url_pattern: ["/dashboard", "/home"])
      expect(tour.matches_url?("/dashboard")).to be true
      expect(tour.matches_url?("/home")).to be true
      expect(tour.matches_url?("/settings")).to be false
    end

    it "matches regex patterns (with backslash)" do
      tour = build(:tour, url_pattern: ['/projects/\d+/edit'])
      expect(tour.matches_url?("/projects/123/edit")).to be true
      expect(tour.matches_url?("/projects/abc/edit")).to be false
    end

    it "returns true when url_pattern is empty (matches all)" do
      tour = build(:tour, url_pattern: [])
      expect(tour.matches_url?("/anything")).to be true
    end
  end
end
