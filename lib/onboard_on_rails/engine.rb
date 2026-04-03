module OnboardOnRails
  class Engine < ::Rails::Engine
    isolate_namespace OnboardOnRails

    initializer "onboard_on_rails.assets.precompile" do |app|
      app.config.assets.precompile += %w[
        onboard_on_rails/admin.js
        onboard_on_rails/admin.css
        onboard_on_rails/client.js
        onboard_on_rails/client.css
      ]
    end
  end
end
