require "rails_helper"

RSpec.describe OnboardOnRails::MetaTagsHelper, type: :helper do
  let(:user) { create(:user) }

  before do
    OnboardOnRails.configuration.current_user_method = :current_user
    # Define current_user method on the helper instance
    def helper.current_user
      @current_user
    end
    helper.instance_variable_set(:@current_user, user)
  end

  describe "#onboard_on_rails_meta_tags" do
    it "includes locale meta tag with default 'ru'" do
      result = helper.onboard_on_rails_meta_tags
      expect(result).to include('name="onboard-on-rails-locale"')
      expect(result).to include('content="ru"')
    end

    it "uses configured user_locale lambda" do
      OnboardOnRails.configuration.user_locale = ->(u) { "en" }

      result = helper.onboard_on_rails_meta_tags
      expect(result).to include('content="en"')
    end
  end
end
