require "rails_helper"

RSpec.describe OnboardOnRails::Admin::ToursController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  before do
    OnboardOnRails.configure do |config|
      config.admin_auth = ->(controller) { true }
    end
  end

  describe "GET #index" do
    it "returns a list of tours" do
      create(:tour, name: "Welcome")
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET #new" do
    it "renders the new tour form" do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a tour" do
      post :create, params: { tour: { name: "New Tour", url_pattern: ["/dashboard/*"] } }
      expect(OnboardOnRails::Tour.count).to eq(1)
      expect(response).to redirect_to(admin_tour_path(OnboardOnRails::Tour.last))
    end
  end

  describe "GET #edit" do
    it "renders the edit form" do
      tour = create(:tour)
      get :edit, params: { id: tour.id }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH #update" do
    it "updates the tour" do
      tour = create(:tour, name: "Old")
      patch :update, params: { id: tour.id, tour: { name: "New" } }
      expect(tour.reload.name).to eq("New")
    end
  end

  describe "DELETE #destroy" do
    it "destroys the tour" do
      tour = create(:tour)
      delete :destroy, params: { id: tour.id }
      expect(OnboardOnRails::Tour.count).to eq(0)
    end
  end

  describe "authorization" do
    it "returns 403 when admin_auth fails" do
      OnboardOnRails.configure { |c| c.admin_auth = ->(ctrl) { false } }
      get :index
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST #copy" do
    it "creates a copy and redirects to edit" do
      tour = create(:tour, name: "Original")
      create(:step, tour: tour, position: 1)

      expect {
        post :copy, params: { id: tour.id }
      }.to change(OnboardOnRails::Tour, :count).by(1)

      copied = OnboardOnRails::Tour.last
      expect(copied.name).to include("Original")
      expect(copied.status).to eq("draft")
      expect(copied.steps.count).to eq(1)
      expect(response).to redirect_to(edit_admin_tour_path(copied))
      expect(flash[:notice]).to eq("Tour copied successfully.")
    end

    it "redirects to index with alert on failure" do
      tour = create(:tour, name: "Original")
      unpersisted = OnboardOnRails::Tour.new
      allow(OnboardOnRails::TourCopier).to receive(:call).and_return(unpersisted)

      post :copy, params: { id: tour.id }

      expect(response).to redirect_to(admin_tours_path)
      expect(flash[:alert]).to eq("Failed to copy tour.")
    end
  end

  describe "PATCH #update with segment_rules_json" do
    it "parses segment_rules_json into segment_rules" do
      tour = create(:tour, name: "Test")
      rules = { "conditions" => [{ "attribute" => "email", "operator" => "starts_with", "value" => "foo" }], "logic" => "and" }

      patch :update, params: { id: tour.id, tour: { segment_rules_json: rules.to_json } }

      tour.reload
      expect(tour.segment_rules["conditions"].first["operator"]).to eq("starts_with")
      expect(tour.segment_rules["logic"]).to eq("and")
    end
  end
end
