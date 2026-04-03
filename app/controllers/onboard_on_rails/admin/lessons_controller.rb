module OnboardOnRails
  module Admin
    class LessonsController < BaseController
      def index
        @lessons = Tour.where(ab_test_id: "self_tour").order(:priority)
      end

      def replay
        tour = Tour.find(params[:id])
        Completion.where(tour: tour, user_id: current_user.id).destroy_all
        redirect_url = Array(tour.url_pattern).first&.gsub(%r{/?\*+\z}, "") || admin_root_path
        redirect_to redirect_url, notice: t("onboard_on_rails.admin.lessons.replayed")
      end

      def seed
        SelfTourSeeder.seed!
        redirect_to admin_lessons_path, notice: t("onboard_on_rails.admin.lessons.seed_success")
      end
    end
  end
end
