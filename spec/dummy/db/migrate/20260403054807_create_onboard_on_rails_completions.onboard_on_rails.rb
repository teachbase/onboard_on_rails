# This migration comes from onboard_on_rails (originally 20260403000003)
class CreateOnboardOnRailsCompletions < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_completions do |t|
      t.references :tour, null: false, foreign_key: { to_table: :onboard_on_rails_tours }
      t.bigint :user_id, null: false
      t.references :step, foreign_key: { to_table: :onboard_on_rails_steps }
      t.string :status, null: false, default: "in_progress"
      t.string :ab_group
      t.string :session_id
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :onboard_on_rails_completions, [:tour_id, :user_id]
    add_index :onboard_on_rails_completions, :user_id
    add_index :onboard_on_rails_completions, :session_id
  end
end
