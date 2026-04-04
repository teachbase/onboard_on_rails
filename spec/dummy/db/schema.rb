# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_04_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "onboard_on_rails_completions", force: :cascade do |t|
    t.string "ab_group"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.jsonb "matched_urls", default: {}, null: false
    t.string "session_id"
    t.datetime "started_at"
    t.string "status", default: "in_progress", null: false
    t.bigint "step_id"
    t.bigint "tour_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["session_id"], name: "index_onboard_on_rails_completions_on_session_id"
    t.index ["step_id"], name: "index_onboard_on_rails_completions_on_step_id"
    t.index ["tour_id", "user_id"], name: "index_onboard_on_rails_completions_on_tour_id_and_user_id"
    t.index ["tour_id"], name: "index_onboard_on_rails_completions_on_tour_id"
    t.index ["user_id"], name: "index_onboard_on_rails_completions_on_user_id"
  end

  create_table "onboard_on_rails_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "user_id", null: false
    t.index ["name"], name: "index_onboard_on_rails_events_on_name"
    t.index ["user_id", "name"], name: "index_onboard_on_rails_events_on_user_id_and_name"
  end

  create_table "onboard_on_rails_steps", force: :cascade do |t|
    t.string "action_type", default: "next", null: false
    t.string "action_value"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "placement", default: "bottom", null: false
    t.integer "position", default: 0, null: false
    t.string "selector", null: false
    t.jsonb "style_overrides", default: {}, null: false
    t.string "title", null: false
    t.bigint "tour_id", null: false
    t.datetime "updated_at", null: false
    t.string "url_pattern"
    t.string "wait_for_selector"
    t.index ["tour_id", "position"], name: "index_onboard_on_rails_steps_on_tour_id_and_position"
    t.index ["tour_id"], name: "index_onboard_on_rails_steps_on_tour_id"
  end

  create_table "onboard_on_rails_tours", force: :cascade do |t|
    t.string "ab_test_group"
    t.string "ab_test_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "frequency", default: "once", null: false
    t.string "name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "schedule_end"
    t.datetime "schedule_start"
    t.jsonb "segment_rules", default: {}, null: false
    t.string "status", default: "draft", null: false
    t.jsonb "style_overrides", default: {}, null: false
    t.string "theme", default: "tooltip", null: false
    t.string "trigger_event"
    t.string "trigger_type", default: "auto", null: false
    t.datetime "updated_at", null: false
    t.jsonb "url_pattern", default: [], null: false
    t.index ["ab_test_id"], name: "index_onboard_on_rails_tours_on_ab_test_id"
    t.index ["status"], name: "index_onboard_on_rails_tours_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "plan", default: "free"
    t.string "role", default: "user"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "onboard_on_rails_completions", "onboard_on_rails_steps", column: "step_id"
  add_foreign_key "onboard_on_rails_completions", "onboard_on_rails_tours", column: "tour_id"
  add_foreign_key "onboard_on_rails_steps", "onboard_on_rails_tours", column: "tour_id"
end
