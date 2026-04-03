module OnboardOnRails
  module Admin
    class StatsController < BaseController
      def show
        @tour = Tour.find(params[:tour_id])
        calculator = StatsCalculator.new(@tour)
        @summary = calculator.summary
        @drop_off = calculator.drop_off_per_step
        @ab_breakdown = calculator.ab_breakdown
        @completions = @tour.completions.includes(:step).order(updated_at: :desc).limit(50)
      end
    end
  end
end
