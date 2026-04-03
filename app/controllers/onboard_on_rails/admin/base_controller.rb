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
        @current_user ||= begin
          method_name = OnboardOnRails.configuration.current_user_method
          host_controller = ::ApplicationController.new
          host_controller.request = request if host_controller.respond_to?(:request=)
          host_controller.send(method_name) if host_controller.respond_to?(method_name, true)
        rescue => e
          Rails.logger.error "[OnboardOnRails] Failed to get current_user: #{e.message}"
          nil
        end
      end
      helper_method :current_user
    end
  end
end
