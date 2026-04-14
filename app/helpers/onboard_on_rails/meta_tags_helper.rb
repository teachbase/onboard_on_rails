module OnboardOnRails
  module MetaTagsHelper
    def onboard_on_rails_meta_tags
      user = send(OnboardOnRails.configuration.current_user_method)
      return "" unless user

      mount_path = OnboardOnRails::Engine.routes.find_script_name({})
      mount_path = "/onboard" if mount_path.blank?

      locale = OnboardOnRails.configuration.user_locale.call(user) || "ru"

      tag.meta(name: "onboard-on-rails-user-id", content: user.id) +
        tag.meta(name: "onboard-on-rails-mount-path", content: mount_path) +
        tag.meta(name: "onboard-on-rails-accent-color", content: OnboardOnRails.configuration.accent_color) +
        tag.meta(name: "csrf-token", content: form_authenticity_token) +
        tag.meta(name: "onboard-on-rails-locale", content: locale)
    end
  end
end
