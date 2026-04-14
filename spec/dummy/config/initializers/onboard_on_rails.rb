OnboardOnRails.configure do |config|
  config.user_class = "User"
  config.current_user_method = :current_user

  config.admin_auth = ->(controller) { true }

  config.register_attribute :user_id, type: :number, label: "User ID",
    description: "ID пользователя в системе" do |user|
    user.id
  end

  config.register_attribute :email, type: :string, label: "Email",
    description: "Email пользователя" do |user|
    user.email
  end

  config.register_attribute :role, type: :string, label: "Роль",
    description: "Роль пользователя",
    values: ["user", "admin"] do |user|
    user.role
  end

  config.register_attribute :plan, type: :string, label: "Тариф",
    description: "Тарифный план",
    values: ["free", "pro", "enterprise"] do |user|
    user.plan
  end
end
