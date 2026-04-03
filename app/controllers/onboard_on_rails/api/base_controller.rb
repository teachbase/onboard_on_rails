module OnboardOnRails
  module Api
    class BaseController < ApplicationController
      skip_forgery_protection
      before_action :authenticate_user!

      private

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

      def authenticate_user!
        head :unauthorized unless current_user
      end
    end
  end
end
