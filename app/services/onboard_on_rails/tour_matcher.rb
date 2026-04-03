module OnboardOnRails
  class TourMatcher
    def initialize(user:, url:, session_id: nil)
      @user = user
      @url = url
      @session_id = session_id
      @user_attributes = OnboardOnRails.configuration.user_attributes.call(user)
    end

    def match
      candidates = base_scope.to_a

      candidates = candidates.select { |t| t.matches_url?(@url) }
      candidates = candidates.select { |t| t.matches_segment?(@user_attributes) }
      candidates = candidates.reject { |t| excluded_by_frequency?(t) }
      candidates = candidates.reject { |t| excluded_by_event_trigger?(t) }
      candidates = candidates.select { |t| included_by_ab_test?(t) }

      candidates.max_by(&:priority)
    end

    private

    def base_scope
      OnboardOnRails::Tour
        .active
        .scheduled_now
        .by_priority
        .includes(:steps)
        .where("EXISTS (SELECT 1 FROM onboard_on_rails_steps WHERE onboard_on_rails_steps.tour_id = onboard_on_rails_tours.id)")
    end

    def excluded_by_frequency?(tour)
      case tour.frequency
      when "always"
        false
      when "once"
        Completion.for_user(@user.id)
          .where(tour: tour)
          .where(status: %w[completed dismissed])
          .exists?
      when "every_session"
        Completion.for_user(@user.id)
          .where(tour: tour, session_id: @session_id)
          .where(status: %w[completed dismissed])
          .exists?
      else
        false
      end
    end

    def excluded_by_event_trigger?(tour)
      return false unless tour.trigger_type == "event"

      !Event.for_user(@user.id).by_name(tour.trigger_event).exists?
    end

    def included_by_ab_test?(tour)
      return true if tour.ab_test_id.blank?

      assigned = AbAssigner.assign_group(user_id: @user.id, tour: tour)
      tour.ab_test_group == assigned
    end
  end
end
