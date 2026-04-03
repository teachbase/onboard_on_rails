module OnboardOnRails
  module Api
    class ToursController < BaseController
      def index
        tour = TourMatcher.new(
          user: current_user,
          url: params[:url],
          session_id: params[:session_id]
        ).match

        if tour
          render json: { tour: serialize_tour(tour) }
        else
          render json: { tour: nil }
        end
      end

      private

      def serialize_tour(tour)
        {
          id: tour.id,
          name: tour.name,
          theme: tour.theme,
          style_overrides: tour.style_overrides,
          steps: tour.steps.map { |s| serialize_step(s) }
        }
      end

      def serialize_step(step)
        {
          id: step.id,
          position: step.position,
          title: step.title,
          body: step.body,
          selector: step.selector,
          placement: step.placement,
          url_pattern: step.url_pattern,
          style_overrides: step.style_overrides,
          action_type: step.action_type,
          action_value: step.action_value,
          wait_for_selector: step.wait_for_selector
        }
      end
    end
  end
end
