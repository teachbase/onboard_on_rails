require "rails_helper"

RSpec.describe OnboardOnRails::Configuration do
  subject(:config) { described_class.new }

  describe "#user_locale" do
    it "defaults to a lambda returning 'ru'" do
      fake_user = double("User")
      expect(config.user_locale.call(fake_user)).to eq("ru")
    end

    it "can be overridden" do
      config.user_locale = ->(user) { user.lang }
      fake_user = double("User", lang: "en")
      expect(config.user_locale.call(fake_user)).to eq("en")
    end
  end

  describe "#register_attribute" do
    it "stores an attribute definition" do
      config.register_attribute(:email, type: :string, label: "Email") { |u| u.email }
      expect(config.registered_attributes).to have_key(:email)
    end

    it "stores all metadata" do
      config.register_attribute(:plan, type: :string, label: "Plan", description: "User plan", values: ["free", "pro"]) { |u| u.plan }
      attr_def = config.registered_attributes[:plan]
      expect(attr_def.key).to eq(:plan)
      expect(attr_def.type).to eq(:string)
      expect(attr_def.label).to eq("Plan")
      expect(attr_def.description).to eq("User plan")
      expect(attr_def.values).to eq(["free", "pro"])
    end

    it "raises if no block given" do
      expect {
        config.register_attribute(:email, type: :string, label: "Email")
      }.to raise_error(ArgumentError, /block required/i)
    end
  end

  describe "#resolve_attributes" do
    it "calls each resolver with the user and returns a hash" do
      fake_user = double("User", email: "foo@bar.com", role: "admin")
      config.register_attribute(:email, type: :string, label: "Email") { |u| u.email }
      config.register_attribute(:role, type: :string, label: "Role") { |u| u.role }

      result = config.resolve_attributes(fake_user)
      expect(result).to eq({ email: "foo@bar.com", role: "admin" })
    end

    it "returns empty hash when no attributes registered" do
      fake_user = double("User")
      expect(config.resolve_attributes(fake_user)).to eq({})
    end
  end

  describe "#attributes_schema" do
    it "returns an array of attribute metadata without resolvers" do
      config.register_attribute(:email, type: :string, label: "Email", description: "User email") { |u| u.email }
      config.register_attribute(:plan, type: :string, label: "Plan", values: ["free", "pro"]) { |u| u.plan }

      schema = config.attributes_schema
      expect(schema).to eq([
        { key: :email, type: :string, label: "Email", description: "User email", values: nil },
        { key: :plan, type: :string, label: "Plan", description: nil, values: ["free", "pro"] }
      ])
    end
  end
end
