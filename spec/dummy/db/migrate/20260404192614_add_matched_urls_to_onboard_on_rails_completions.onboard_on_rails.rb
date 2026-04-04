# This migration comes from onboard_on_rails (originally 20260404000001)
class AddMatchedUrlsToOnboardOnRailsCompletions < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_completions, :matched_urls, :jsonb, null: false, default: {}
  end
end
