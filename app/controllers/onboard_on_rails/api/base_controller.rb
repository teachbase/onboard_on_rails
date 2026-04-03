module OnboardOnRails
  module Api
    class BaseController < ApplicationController
      skip_forgery_protection
      before_action :authenticate_user!

      private

      def current_user
        method_name = OnboardOnRails.configuration.current_user_method
        main_app_controller = request.env["action_controller.instance"]
        if main_app_controller&.respond_to?(method_name, true)
          main_app_controller.send(method_name)
        else
          send(method_name) if respond_to?(method_name, true)
        end
      end

      def authenticate_user!
        head :unauthorized unless current_user
      end
    end
  end
end
