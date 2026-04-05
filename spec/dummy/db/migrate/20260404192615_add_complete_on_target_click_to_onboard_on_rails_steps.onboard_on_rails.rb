# This migration comes from onboard_on_rails (originally 20260404000002)
class AddCompleteOnTargetClickToOnboardOnRailsSteps < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_steps, :complete_on_target_click, :boolean, default: false, null: false
  end
end
