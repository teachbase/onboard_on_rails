module OnboardOnRails
  module Api
    class ToursController < BaseController
      def index
        matcher = TourMatcher.new(
          user: current_user,
          url: params[:url],
          session_id: params[:session_id],
          device_type: params[:device_type],
          request: request
        )
        tour = matcher.match

        if tour
          completion = Completion.find_by(tour: tour, user_id: current_user.id)
          render json: {
            tour: serialize_tour(tour, matcher.current_step_index, completion)
          }
        else
          render json: { tour: nil }
        end
      end

      private

      def serialize_tour(tour, current_step_index, completion)
        matched_urls = completion&.matched_urls || {}
        {
          id: tour.id,
          name: tour.name,
          theme: tour.theme,
          style_overrides: tour.style_overrides,
          current_step_index: current_step_index,
          steps: tour.steps.sort_by(&:position).map { |s| serialize_step(s, matched_urls) }
        }
      end

      def serialize_step(step, matched_urls)
        {
          id: step.id,
          position: step.position,
          title: step.title,
          body: step.body,
          selector: step.selector,
          placement: step.placement,
          url_pattern: step.url_pattern,
          matched_url: matched_urls[step.id.to_s],
          style_overrides: step.style_overrides,
          action_type: step.action_type,
          action_value: step.action_value,
          wait_for_selector: step.wait_for_selector,
          complete_on_target_click: step.complete_on_target_click
        }
      end
    end
  end
end
