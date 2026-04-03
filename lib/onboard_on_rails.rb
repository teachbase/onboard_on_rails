require "onboard_on_rails/version"
require "onboard_on_rails/configuration"
require "onboard_on_rails/engine"

module OnboardOnRails
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def track_event(user, name, payload = {})
      OnboardOnRails::Event.create!(
        user_id: user.id,
        name: name,
        payload: payload
      )
    end
  end
end
