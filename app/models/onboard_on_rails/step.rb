module OnboardOnRails
  class Step < ApplicationRecord
    self.table_name = "onboard_on_rails_steps"

    PLACEMENTS = %w[top bottom left right center].freeze
    ACTION_TYPES = %w[next redirect custom_event].freeze

    belongs_to :tour
    has_many :completions, dependent: :nullify

    validates :title, presence: true
    validates :selector, presence: true
    validates :placement, inclusion: { in: PLACEMENTS }
    validates :action_type, inclusion: { in: ACTION_TYPES }
  end
end
