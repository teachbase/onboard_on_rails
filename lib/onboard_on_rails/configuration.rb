module OnboardOnRails
  class Configuration
    attr_accessor :user_class, :admin_auth, :user_attributes, :current_user_method

    def initialize
      @user_class = "User"
      @admin_auth = ->(controller) { true }
      @user_attributes = ->(user) { {} }
      @current_user_method = :current_user
    end
  end
end
