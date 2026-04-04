module OnboardOnRails
  module Admin
    class LessonsController < BaseController
      def index
        @lessons = Tour.where(ab_test_id: "self_tour").order(priority: :desc)
      end

      def replay
        tour = Tour.find(params[:id])
        Completion.where(tour: tour, user_id: current_user.id).destroy_all
        redirect_to resolve_lesson_url(tour), notice: t("onboard_on_rails.admin.lessons.replayed")
      end

      def seed
        SelfTourSeeder.seed!
        redirect_to admin_lessons_path, notice: t("onboard_on_rails.admin.lessons.seed_success")
      end

      def recreate
        self_tours = Tour.where(ab_test_id: "self_tour")
        Completion.where(tour: self_tours).destroy_all
        self_tours.destroy_all
        SelfTourSeeder.seed!
        redirect_to admin_lessons_path, notice: t("onboard_on_rails.admin.lessons.recreate_success")
      end

      private

      def resolve_lesson_url(tour)
        pattern = Array(tour.url_pattern).first
        return admin_root_path if pattern.blank?

        if pattern.include?("*")
          sample_tour = Tour.where.not(ab_test_id: "self_tour").order(updated_at: :desc).first
          if sample_tour
            url = pattern.gsub("*", sample_tour.id.to_s)
            return url
          end
        end

        pattern.gsub(%r{/?\*+\z}, "").presence || admin_root_path
      end
    end
  end
end
