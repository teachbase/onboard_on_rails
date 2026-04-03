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

      private

      def resolve_lesson_url(tour)
        pattern = Array(tour.url_pattern).first
        return admin_root_path if pattern.blank?

        # If pattern contains wildcards, try to resolve with a real tour
        if pattern.include?("*")
          sample_tour = Tour.where.not(ab_test_id: "self_tour").order(updated_at: :desc).first
          if sample_tour
            url = pattern.gsub("*", sample_tour.id.to_s)
            return url
          end
        end

        # Strip trailing wildcards for simple patterns
        pattern.gsub(%r{/?\*+\z}, "").presence || admin_root_path
      end

      def seed
        SelfTourSeeder.seed!
        redirect_to admin_lessons_path, notice: t("onboard_on_rails.admin.lessons.seed_success")
      end
    end
  end
end
