class AddCompleteOnTargetClickToOnboardOnRailsSteps < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_steps, :complete_on_target_click, :boolean, default: false, null: false
  end
end
