module OnboardOnRails
  module Admin
    class StepsController < BaseController
      before_action :set_tour
      before_action :set_step, only: [:edit, :update, :destroy]

      def new
        @step = @tour.steps.build(position: @tour.steps.count + 1)
      end

      def create
        @step = @tour.steps.build(step_params)
        @step.position ||= @tour.steps.count
        if @step.save
          redirect_to edit_admin_tour_step_path(@tour, @step), notice: t("onboard_on_rails.flash.step_created")
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @step.update(step_params)
          redirect_to edit_admin_tour_step_path(@tour, @step), notice: t("onboard_on_rails.flash.step_updated")
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @step.destroy
        redirect_to edit_admin_tour_path(@tour), notice: t("onboard_on_rails.flash.step_deleted")
      end

      private

      def set_tour
        @tour = Tour.find(params[:tour_id])
      end

      def set_step
        @step = @tour.steps.find(params[:id])
      end

      def step_params
        params.require(:step).permit(
          :title, :body, :selector, :placement, :position,
          :url_pattern, :action_type, :action_value, :wait_for_selector,
          style_overrides: {}
        )
      end
    end
  end
end
