class ApplicationController < ActionController::Base
  def current_user
    @current_user ||= User.first_or_create!(
      email: "admin@example.com",
      role: "admin",
      plan: "pro"
    )
  end
  helper_method :current_user
end
