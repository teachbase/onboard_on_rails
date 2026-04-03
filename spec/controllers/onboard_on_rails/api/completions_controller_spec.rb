require "rails_helper"

RSpec.describe OnboardOnRails::Api::CompletionsController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:user) { User.create!(email: "test@test.com") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    let(:tour) { create(:tour) }
    let(:step) { create(:step, tour: tour) }

    it "creates a new completion" do
      post :create, params: {
        tour_id: tour.id,
        step_id: step.id,
        status: "in_progress",
        session_id: "abc123"
      }, format: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["completion"]["tour_id"]).to eq(tour.id)
    end

    it "updates existing completion for same user + tour" do
      existing = create(:completion, tour: tour, user_id: user.id, status: "in_progress")

      post :create, params: {
        tour_id: tour.id,
        step_id: step.id,
        status: "completed",
        session_id: "abc123"
      }, format: :json

      expect(response).to have_http_status(:ok)
      expect(existing.reload.status).to eq("completed")
    end
  end
end
