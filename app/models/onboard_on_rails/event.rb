module OnboardOnRails
  class Event < ApplicationRecord
    self.table_name = "onboard_on_rails_events"

    validates :user_id, presence: true
    validates :name, presence: true

    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :by_name, ->(name) { where(name: name) }
  end
end
