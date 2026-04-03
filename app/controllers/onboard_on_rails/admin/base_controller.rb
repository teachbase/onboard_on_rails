module OnboardOnRails
  module Admin
    class BaseController < ApplicationController
      layout "onboard_on_rails/admin"
      before_action :authorize_admin!

      private

      def authorize_admin!
        auth = OnboardOnRails.configuration.admin_auth
        unless auth.call(self)
          head :forbidden
        end
      end

      def current_user
        method_name = OnboardOnRails.configuration.current_user_method
        send(method_name) if respond_to?(method_name, true)
      end
      helper_method :current_user
    end
  end
end
