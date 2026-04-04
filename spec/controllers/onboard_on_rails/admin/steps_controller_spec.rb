require "rails_helper"

RSpec.describe OnboardOnRails::Admin::StepsController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:tour) { create(:tour) }

  before do
    OnboardOnRails.configure do |config|
      config.admin_auth = ->(controller) { true }
    end
  end

  describe "GET #new" do
    it "renders the new step form" do
      get :new, params: { tour_id: tour.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a step" do
      post :create, params: {
        tour_id: tour.id,
        step: { title: "Hello", selector: "#main", placement: "bottom" }
      }
      expect(tour.steps.count).to eq(1)
    end
  end

  describe "GET #edit" do
    it "renders the step editor with preview" do
      step = create(:step, tour: tour)
      get :edit, params: { tour_id: tour.id, id: step.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    it "updates the step" do
      step = create(:step, tour: tour, title: "Old")
      patch :update, params: { tour_id: tour.id, id: step.id, step: { title: "New" } }
      expect(step.reload.title).to eq("New")
    end
  end

  describe "PATCH #update complete_on_target_click" do
    it "saves complete_on_target_click flag" do
      step = create(:step, tour: tour, complete_on_target_click: false)
      patch :update, params: {
        tour_id: tour.id, id: step.id,
        step: { complete_on_target_click: "1" }
      }
      expect(step.reload.complete_on_target_click).to eq(true)
    end
  end

  describe "DELETE #destroy" do
    it "destroys the step" do
      step = create(:step, tour: tour)
      delete :destroy, params: { tour_id: tour.id, id: step.id }
      expect(tour.steps.count).to eq(0)
    end
  end
end
