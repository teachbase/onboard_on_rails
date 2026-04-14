require "rails_helper"

RSpec.describe OnboardOnRails::Configuration do
  subject(:config) { described_class.new }

  describe "#accent_color" do
    it "defaults to #2d3436" do
      expect(config.accent_color).to eq("#2d3436")
    end

    it "accepts custom color" do
      config.accent_color = "#ff6600"
      expect(config.accent_color).to eq("#ff6600")
    end
  end

  describe "#accent_color_dark" do
    it "returns a darker shade of the accent color" do
      config.accent_color = "#6c5ce7"
      dark = config.accent_color_dark
      expect(dark).to match(/\A#[0-9a-f]{6}\z/i)
      # Should be darker than original
      r, g, b = dark[1..2].to_i(16), dark[3..4].to_i(16), dark[5..6].to_i(16)
      expect(r).to be < 0x6c
      expect(g).to be < 0x5c
      expect(b).to be < 0xe7
    end
  end

  describe "#accent_color_light" do
    it "returns a lighter shade of the accent color" do
      config.accent_color = "#2d3436"
      light = config.accent_color_light
      expect(light).to match(/\A#[0-9a-f]{6}\z/i)
      r, g, b = light[1..2].to_i(16), light[3..4].to_i(16), light[5..6].to_i(16)
      expect(r).to be > 0x2d
      expect(g).to be > 0x34
      expect(b).to be > 0x36
    end
  end

  describe "#accent_color_rgba" do
    it "returns rgba string with given alpha" do
      config.accent_color = "#2d3436"
      expect(config.accent_color_rgba(0.15)).to eq("rgba(45, 52, 54, 0.15)")
    end

    it "works with bright colors" do
      config.accent_color = "#ff0000"
      expect(config.accent_color_rgba(0.5)).to eq("rgba(255, 0, 0, 0.5)")
    end
  end
end
