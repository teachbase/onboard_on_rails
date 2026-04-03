module OnboardOnRails
  class Engine < ::Rails::Engine
    isolate_namespace OnboardOnRails

    initializer "onboard_on_rails.helpers" do
      ActiveSupport.on_load(:action_view) do
        include OnboardOnRails::MetaTagsHelper
      end
    end

    initializer "onboard_on_rails.assets.precompile" do |app|
      if app.config.respond_to?(:assets) && app.config.assets.respond_to?(:precompile)
        app.config.assets.precompile += %w[
          onboard_on_rails/admin.js
          onboard_on_rails/admin.css
          onboard_on_rails/client.js
          onboard_on_rails/client.css
        ]
      end
    end
  end
end
