class CreateOnboardOnRailsSteps < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_steps do |t|
      t.references :tour, null: false, foreign_key: { to_table: :onboard_on_rails_tours }
      t.integer :position, null: false, default: 0
      t.string :title, null: false
      t.text :body
      t.string :selector, null: false
      t.string :placement, null: false, default: "bottom"
      t.string :url_pattern
      t.jsonb :style_overrides, null: false, default: {}
      t.string :action_type, null: false, default: "next"
      t.string :action_value
      t.string :wait_for_selector
      t.timestamps
    end

    add_index :onboard_on_rails_steps, [:tour_id, :position]
  end
end
