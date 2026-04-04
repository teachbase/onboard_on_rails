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

    def matches_step_url?(url)
      return true if url_pattern.blank?

      pattern = url_pattern.to_s
      if pattern.include?("\\")
        Regexp.new("\\A#{pattern}\\z").match?(url)
      else
        regex = glob_to_regex(pattern)
        regex.match?(url)
      end
    end

    private

    def glob_to_regex(glob)
      escaped = Regexp.escape(glob)
      escaped = escaped.gsub("\\*\\*", "DOUBLE_STAR")
      escaped = escaped.gsub("\\*", "[^/]*")
      escaped = escaped.gsub("DOUBLE_STAR", ".*")
      Regexp.new("\\A#{escaped}\\z")
    end
  end
end
