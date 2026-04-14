# This migration comes from onboard_on_rails (originally 20260414000001)
class AddOverlayEnabledToOnboardOnRailsTours < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_tours, :overlay_enabled, :boolean, default: true, null: false
  end
end
