require "rails_helper"

RSpec.describe OnboardOnRails::Admin::StatsController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:tour) { create(:tour) }

  before do
    OnboardOnRails.configure { |c| c.admin_auth = ->(controller) { true } }
  end

  describe "GET #export" do
    it "returns a CSV file as an attachment" do
      create(:completion, tour: tour, user_id: 1, status: "dismissed")

      get :export, params: { tour_id: tour.id }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Disposition"]).to include("attachment")
      expect(response.headers["Content-Disposition"]).to include("tour-#{tour.id}-completions-")
      expect(response.body).to include("dismissed")
    end

    it "returns 403 when admin_auth fails" do
      OnboardOnRails.configure { |c| c.admin_auth = ->(controller) { false } }

      get :export, params: { tour_id: tour.id }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
