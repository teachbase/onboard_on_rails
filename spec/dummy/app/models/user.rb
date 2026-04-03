class User < ApplicationRecord
  def admin?
    role == "admin"
  end
end
