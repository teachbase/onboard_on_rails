module OnboardOnRails
  class SelectorPickerController < Admin::BaseController
    def show
      @tour = Tour.find_by(id: params[:tour_id])
      @step = @tour&.steps&.find_by(id: params[:step_id]) if params[:step_id].present?
      @target_url = params[:url] || resolve_target_url || "/"
      render layout: false
    end

    private

    def resolve_target_url
      if @step&.url_pattern.present? && !@step.url_pattern.include?("*")
        return @step.url_pattern
      end

      pattern = Array(@tour&.url_pattern).first
      return nil if pattern.blank?

      url = pattern.gsub(%r{/?\*+\z}, "")
      url = "/" if url.blank?
      url
    end
  end
end
