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

    it "stores matched_url in matched_urls hash" do
      tour_record = create(:tour)
      step1 = create(:step, tour: tour_record, position: 1)
      step2 = create(:step, tour: tour_record, position: 2)

      post :create, params: {
        tour_id: tour_record.id,
        step_id: step2.id,
        status: "in_progress",
        session_id: "abc123",
        matched_url: "/teacher/students",
        matched_step_id: step1.id
      }, format: :json

      expect(response).to have_http_status(:created)
      completion = OnboardOnRails::Completion.last
      expect(completion.step_id).to eq(step2.id)
      expect(completion.matched_urls[step1.id.to_s]).to eq("/teacher/students")
    end

    it "accumulates matched_urls across multiple next calls" do
      tour_record = create(:tour)
      step1 = create(:step, tour: tour_record, position: 1)
      step2 = create(:step, tour: tour_record, position: 2)
      step3 = create(:step, tour: tour_record, position: 3)

      post :create, params: {
        tour_id: tour_record.id, step_id: step2.id, status: "in_progress",
        session_id: "s1", matched_url: "/page-a", matched_step_id: step1.id
      }, format: :json

      post :create, params: {
        tour_id: tour_record.id, step_id: step3.id, status: "in_progress",
        session_id: "s1", matched_url: "/page-b", matched_step_id: step2.id
      }, format: :json

      completion = OnboardOnRails::Completion.find_by(tour_id: tour_record.id, user_id: user.id)
      expect(completion.matched_urls[step1.id.to_s]).to eq("/page-a")
      expect(completion.matched_urls[step2.id.to_s]).to eq("/page-b")
    end
  end
end
