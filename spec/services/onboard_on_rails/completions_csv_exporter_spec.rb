require "rails_helper"
require "csv"

RSpec.describe OnboardOnRails::CompletionsCsvExporter do
  let(:tour) { create(:tour) }
  let!(:step) { create(:step, tour: tour, position: 2, title: "Pick a plan") }

  before do
    OnboardOnRails.configure do |config|
      config.register_attribute(:csv_plan, type: :string, label: "Plan Column") { |u| u.plan }
    end
  end

  after do
    # Configuration is a global singleton with no reset between examples;
    # remove the attribute we registered so it does not leak into other specs.
    OnboardOnRails.configuration.registered_attributes.delete(:csv_plan)
  end

  def parse(csv_string)
    CSV.parse(csv_string.delete_prefix("\uFEFF"), headers: true)
  end

  describe "#to_csv" do
    it "starts with a UTF-8 BOM" do
      expect(described_class.new(tour).to_csv).to start_with("\uFEFF")
    end

    it "includes base column headers and registered attribute labels" do
      table = parse(described_class.new(tour).to_csv)
      expect(table.headers).to include(
        "Status", "Last Step Position", "Last Step Title",
        "Started At", "Completed At", "Plan Column"
      )
    end

    it "emits one row per completion with no 50-row limit" do
      55.times { |i| create(:completion, tour: tour, user_id: i + 1, status: "dismissed") }
      table = parse(described_class.new(tour).to_csv)
      expect(table.size).to eq(55)
    end

    it "exports the raw (non-localized) status value" do
      create(:completion, tour: tour, user_id: 1, status: "dismissed", step: step)
      row = parse(described_class.new(tour).to_csv).first
      expect(row["Status"]).to eq("dismissed")
    end

    it "fills email and attribute columns from the user record" do
      user = User.create!(email: "marketing@example.com", role: "user", plan: "pro")
      create(:completion, tour: tour, user_id: user.id, status: "dismissed")
      row = parse(described_class.new(tour).to_csv).first
      expect(row["Email"]).to eq("marketing@example.com")
      expect(row["Plan Column"]).to eq("pro")
    end

    it "leaves email and attribute columns blank when the user is missing" do
      create(:completion, tour: tour, user_id: 999_999, status: "dismissed")
      row = parse(described_class.new(tour).to_csv).first
      expect(row["Email"]).to be_nil
      expect(row["Plan Column"]).to be_nil
    end

    it "records the last step position and title" do
      create(:completion, tour: tour, user_id: 1, status: "dismissed", step: step)
      row = parse(described_class.new(tour).to_csv).first
      expect(row["Last Step Position"]).to eq("2")
      expect(row["Last Step Title"]).to eq("Pick a plan")
    end

    it "returns only the header row when there are no completions" do
      table = parse(described_class.new(tour).to_csv)
      expect(table.size).to eq(0)
    end
  end

  describe "#filename" do
    it "is tour-scoped and date-stamped" do
      expect(described_class.new(tour).filename)
        .to match(/\Atour-#{tour.id}-completions-\d{8}\.csv\z/)
    end
  end
end
