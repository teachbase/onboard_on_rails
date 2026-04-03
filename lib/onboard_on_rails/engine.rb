module OnboardOnRails
  class Engine < ::Rails::Engine
    isolate_namespace OnboardOnRails

    initializer "onboard_on_rails.i18n" do
      OnboardOnRails::Engine.root.glob("config/locales/**/*.yml").each do |locale|
        I18n.load_path += [locale]
      end
    end

    initializer "onboard_on_rails.helpers" do
      ActiveSupport.on_load(:action_view) do
        require OnboardOnRails::Engine.root.join("app", "helpers", "onboard_on_rails", "meta_tags_helper").to_s
        include OnboardOnRails::MetaTagsHelper
      end
    end

    initializer "onboard_on_rails.assets", after: :append_assets_path do |app|
      js_path = root.join("app", "assets", "javascripts").to_s
      app.config.assets.paths << js_path unless app.config.assets.paths.map(&:to_s).include?(js_path)

      if app.config.assets.respond_to?(:precompile)
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
