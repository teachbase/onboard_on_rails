require "rails_helper"

RSpec.describe OnboardOnRails::Api::EventsController, type: :controller do
  routes { OnboardOnRails::Engine.routes }

  let(:user) { User.create!(email: "test@test.com") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe "POST #create" do
    it "creates an event" do
      post :create, params: {
        name: "first_project_created",
        payload: { project_id: 42 }
      }, format: :json

      expect(response).to have_http_status(:created)
      expect(OnboardOnRails::Event.last.name).to eq("first_project_created")
      expect(OnboardOnRails::Event.last.user_id).to eq(user.id)
    end
  end
end
