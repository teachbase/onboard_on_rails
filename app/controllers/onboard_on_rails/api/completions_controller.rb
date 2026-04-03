module OnboardOnRails
  module Api
    class CompletionsController < BaseController
      def create
        completion = Completion.find_or_initialize_by(
          tour_id: params[:tour_id],
          user_id: current_user.id
        )

        was_new = completion.new_record?
        completion.step_id = params[:step_id]
        completion.status = params[:status]
        completion.session_id = params[:session_id]
        completion.started_at ||= Time.current
        completion.completed_at = Time.current if params[:status] == "completed"

        if completion.save
          status_code = was_new ? :created : :ok
          render json: { completion: { id: completion.id, tour_id: completion.tour_id, status: completion.status } }, status: status_code
        else
          render json: { errors: completion.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
