module OnboardOnRails
  class Completion < ApplicationRecord
    self.table_name = "onboard_on_rails_completions"

    STATUSES = %w[in_progress completed dismissed].freeze

    belongs_to :tour
    belongs_to :step, optional: true

    validates :user_id, presence: true
    validates :status, inclusion: { in: STATUSES }

    scope :for_user, ->(user_id) { where(user_id: user_id) }
    scope :in_progress, -> { where(status: "in_progress") }
    scope :completed, -> { where(status: "completed") }
    scope :dismissed, -> { where(status: "dismissed") }
  end
end
