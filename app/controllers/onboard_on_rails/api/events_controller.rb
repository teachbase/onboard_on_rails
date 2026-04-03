module OnboardOnRails
  module Api
    class EventsController < BaseController
      def create
        event = Event.new(
          user_id: current_user.id,
          name: params[:name],
          payload: params[:payload] || {}
        )

        if event.save
          render json: { event: { id: event.id, name: event.name } }, status: :created
        else
          render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end
end
