module OnboardOnRails
  module Admin
    class ToursController < BaseController
      before_action :set_tour, only: [:show, :edit, :update, :destroy, :copy]

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
          redirect_to admin_tour_path(@tour), notice: t("onboard_on_rails.flash.tour_created")
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
          redirect_to edit_admin_tour_path(@tour), notice: t("onboard_on_rails.flash.tour_updated")
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @tour.destroy
        redirect_to admin_tours_path, notice: t("onboard_on_rails.flash.tour_deleted")
      end

      def copy
        copied = TourCopier.call(@tour)

        if copied.persisted?
          redirect_to edit_admin_tour_path(copied), notice: t(".success")
        else
          redirect_to admin_tours_path, alert: t(".failure")
        end
      end

      private

      def set_tour
        @tour = Tour.find(params[:id])
      end

      def tour_params
        permitted = params.require(:tour).permit(
          :name, :description, :status, :trigger_type, :trigger_event,
          :frequency, :theme, :priority, :schedule_start, :schedule_end,
          :ab_test_id, :ab_test_group,
          style_overrides: {}, segment_rules: {}
        )

        if params[:tour].key?(:url_pattern)
          if params[:tour][:url_pattern].is_a?(String)
            permitted[:url_pattern] = params[:tour][:url_pattern].split(",").map(&:strip).reject(&:blank?)
          else
            permitted[:url_pattern] = params[:tour].permit(url_pattern: [])[:url_pattern] || []
          end
        end

        permitted
      end
    end
  end
end
