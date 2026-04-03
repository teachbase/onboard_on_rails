# This migration comes from onboard_on_rails (originally 20260403000001)
class CreateOnboardOnRailsTours < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_tours do |t|
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "draft"
      t.string :trigger_type, null: false, default: "auto"
      t.string :trigger_event
      t.jsonb :url_pattern, null: false, default: []
      t.jsonb :segment_rules, null: false, default: {}
      t.datetime :schedule_start
      t.datetime :schedule_end
      t.string :frequency, null: false, default: "once"
      t.string :ab_test_group
      t.string :ab_test_id
      t.string :theme, null: false, default: "tooltip"
      t.jsonb :style_overrides, null: false, default: {}
      t.integer :priority, null: false, default: 0
      t.timestamps
    end

    add_index :onboard_on_rails_tours, :status
    add_index :onboard_on_rails_tours, :ab_test_id
  end
end
