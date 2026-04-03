require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)
require "onboard_on_rails"

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("../..", __FILE__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.i18n.default_locale = :ru
    config.i18n.available_locales = [:ru, :en]
  end
end
