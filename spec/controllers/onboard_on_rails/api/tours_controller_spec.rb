require "rails_helper"

RSpec.describe OnboardOnRails::Api::ToursController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:user) { User.create!(email: "test@test.com", role: "admin", plan: "pro") }

  before do
    OnboardOnRails.configure do |config|
      config.current_user_method = :current_user
      config.user_attributes = ->(u) { { role: u.role, plan: u.plan } }
    end
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "GET #index" do
    it "returns matching tour with steps as JSON" do
      tour = create(:tour, url_pattern: ["/dashboard/*"])
      step = create(:step, tour: tour, position: 1)

      get :index, params: { url: "/dashboard/home" }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tour"]["id"]).to eq(tour.id)
      expect(json["tour"]["steps"].length).to eq(1)
      expect(json["tour"]["steps"][0]["id"]).to eq(step.id)
    end

    it "returns empty when no tours match" do
      get :index, params: { url: "/unknown" }, format: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tour"]).to be_nil
    end

    it "returns 401 when no user" do
      allow(controller).to receive(:current_user).and_return(nil)

      get :index, params: { url: "/dashboard" }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
