class AddDeviceTypeToOnboardOnRailsTours < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_tours, :device_type, :string, default: "all", null: false
  end
end
