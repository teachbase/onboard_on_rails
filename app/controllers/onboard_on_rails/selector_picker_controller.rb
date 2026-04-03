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
      pattern = Array(@tour&.url_pattern).first
      return nil if pattern.blank?

      # Strip glob wildcards to get a navigable base path
      # "/dashboard/*" → "/dashboard"
      # "/projects/**" → "/projects"
      # "/settings" → "/settings" (unchanged)
      url = pattern.gsub(%r{/?\*+\z}, "")
      url = "/" if url.blank?
      url
    end
  end
end
