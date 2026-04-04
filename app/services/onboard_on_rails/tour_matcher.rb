module OnboardOnRails
  class TourMatcher
    attr_reader :current_step_index

    def initialize(user:, url:, session_id: nil)
      @user = user
      @url = url
      @session_id = session_id
      @user_attributes = OnboardOnRails.configuration.user_attributes.call(user)
      @current_step_index = 0
    end

    def match
      # First: try to resume an in-progress tour
      resumed = find_in_progress_tour
      return resumed if resumed

      # Otherwise: normal matching for new tours
      candidates = base_scope.to_a
      candidates = candidates.select { |t| t.matches_url?(@url) }
      candidates = candidates.select { |t| t.matches_segment?(@user_attributes) }
      candidates = candidates.reject { |t| excluded_by_frequency?(t) }
      candidates = candidates.reject { |t| excluded_by_event_trigger?(t) }
      candidates = candidates.select { |t| included_by_ab_test?(t) }

      result = candidates.max_by(&:priority)
      @current_step_index = 0
      result
    end

    private

    def find_in_progress_tour
      completions = Completion.for_user(@user.id)
        .in_progress
        .includes(tour: :steps)

      completions.each do |completion|
        tour = completion.tour
        next unless tour.status == "active"

        steps = tour.steps.sort_by(&:position)
        step_index = steps.index { |s| s.id == completion.step_id }
        next unless step_index

        current_step = steps[step_index]
        if step_matches_url?(current_step, tour)
          @current_step_index = step_index
          return tour
        end
      end

      nil
    end

    def step_matches_url?(step, tour)
      if step.url_pattern.present?
        step.matches_step_url?(@url)
      else
        tour.matches_url?(@url)
      end
    end

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
