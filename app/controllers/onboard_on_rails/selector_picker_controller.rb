module OnboardOnRails
  class SelectorPickerController < Admin::BaseController
    def show
      @tour = Tour.find_by(id: params[:tour_id])
      @step = @tour&.steps&.find_by(id: params[:step_id]) if params[:step_id].present?
      @target_url = params[:url] || Array(@tour&.url_pattern).first || "/"
      render layout: false
    end
  end
end
