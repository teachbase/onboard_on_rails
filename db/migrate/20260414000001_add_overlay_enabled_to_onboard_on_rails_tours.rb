class AddOverlayEnabledToOnboardOnRailsTours < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_tours, :overlay_enabled, :boolean, default: true, null: false
  end
end
