module OnboardOnRails
  class Tour < ApplicationRecord
    self.table_name = "onboard_on_rails_tours"

    include Concerns::UrlMatchable
    include Concerns::SegmentEvaluator

    STATUSES = %w[draft active archived].freeze
    TRIGGER_TYPES = %w[auto event manual].freeze
    FREQUENCIES = %w[once every_session always].freeze
    THEMES = %w[tooltip modal banner slideout].freeze
    DEVICE_TYPES = %w[all desktop mobile].freeze

    has_many :steps, -> { order(:position) }, dependent: :destroy
    has_many :completions, dependent: :destroy

    validates :name, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :trigger_type, inclusion: { in: TRIGGER_TYPES }
    validates :frequency, inclusion: { in: FREQUENCIES }
    validates :theme, inclusion: { in: THEMES }
    validates :device_type, inclusion: { in: DEVICE_TYPES }
    validates :trigger_event, presence: true, if: -> { trigger_type == "event" }

    scope :active, -> { where(status: "active") }
    scope :scheduled_now, -> {
      now = Time.current
      where("schedule_start IS NULL OR schedule_start <= ?", now)
        .where("schedule_end IS NULL OR schedule_end >= ?", now)
    }
    scope :by_priority, -> { order(priority: :desc) }
  end
end
