require "rails_helper"

RSpec.describe OnboardOnRails::Configuration do
  describe "#user_locale" do
    it "defaults to a lambda returning 'ru'" do
      config = described_class.new
      fake_user = double("User")
      expect(config.user_locale.call(fake_user)).to eq("ru")
    end

    it "can be overridden" do
      config = described_class.new
      config.user_locale = ->(user) { user.lang }
      fake_user = double("User", lang: "en")
      expect(config.user_locale.call(fake_user)).to eq("en")
    end
  end
end
