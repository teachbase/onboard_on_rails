require "csv"

module OnboardOnRails
  class CompletionsCsvExporter
    TIMESTAMP_FORMAT = "%Y-%m-%d %H:%M:%S".freeze
    BOM = "\uFEFF".freeze
    BASE_COLUMNS = %i[
      user_id user_email status
      last_step_position last_step_title
      started_at completed_at
    ].freeze

    def initialize(tour)
      @tour = tour
    end

    def filename
      "tour-#{@tour.id}-completions-#{Date.current.strftime('%Y%m%d')}.csv"
    end

    def to_csv
      attribute_defs = OnboardOnRails.configuration.registered_attributes.values
      completions = @tour.completions.includes(:step).order(updated_at: :desc).to_a
      users = preload_users(completions)

      body = CSV.generate do |csv|
        csv << header_row(attribute_defs)
        completions.each do |completion|
          csv << data_row(completion, users[completion.user_id], attribute_defs)
        end
      end

      BOM + body
    end

    private

    def header_row(attribute_defs)
      BASE_COLUMNS.map { |key| I18n.t("onboard_on_rails.admin.stats.csv.#{key}") } +
        attribute_defs.map(&:label)
    end

    def data_row(completion, user, attribute_defs)
      [
        completion.user_id,
        user_email(user),
        completion.status,
        completion.step&.position,
        completion.step&.title,
        format_time(completion.started_at),
        format_time(completion.completed_at)
      ] + attribute_defs.map { |attr| user ? attr.resolver.call(user) : nil }
    end

    def preload_users(completions)
      klass = user_class
      return {} unless klass

      ids = completions.map(&:user_id).compact.uniq
      return {} if ids.empty?

      klass.where(id: ids).index_by(&:id)
    end

    def user_class
      OnboardOnRails.configuration.user_class&.constantize
    rescue NameError
      nil
    end

    def user_email(user)
      return nil unless user.respond_to?(:email)

      user.email
    end

    def format_time(time)
      time&.strftime(TIMESTAMP_FORMAT)
    end
  end
end
