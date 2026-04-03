module OnboardOnRails
  module Admin
    class ToursController < BaseController
      before_action :set_tour, only: [:show, :edit, :update, :destroy]

      def index
        @tours = Tour.order(updated_at: :desc)
        @tours = @tours.where(status: params[:status]) if params[:status].present?
      end

      def new
        @tour = Tour.new
      end

      def create
        @tour = Tour.new(tour_params)
        if @tour.save
          redirect_to admin_tour_path(@tour), notice: "Tour created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def show
        redirect_to edit_admin_tour_path(@tour)
      end

      def edit
      end

      def update
        if @tour.update(tour_params)
          redirect_to edit_admin_tour_path(@tour), notice: "Tour updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @tour.destroy
        redirect_to admin_tours_path, notice: "Tour deleted."
      end

      private

      def set_tour
        @tour = Tour.find(params[:id])
      end

      def tour_params
        params.require(:tour).permit(
          :name, :description, :status, :trigger_type, :trigger_event,
          :frequency, :theme, :priority, :schedule_start, :schedule_end,
          :ab_test_id, :ab_test_group,
          url_pattern: [], style_overrides: {}, segment_rules: {}
        )
      end
    end
  end
end
