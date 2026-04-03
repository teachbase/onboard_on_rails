class CreateOnboardOnRailsEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :onboard_on_rails_events do |t|
      t.bigint :user_id, null: false
      t.string :name, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :onboard_on_rails_events, [:user_id, :name]
    add_index :onboard_on_rails_events, :name
  end
end
