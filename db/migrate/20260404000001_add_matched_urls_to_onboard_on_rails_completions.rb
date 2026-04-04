class AddMatchedUrlsToOnboardOnRailsCompletions < ActiveRecord::Migration[7.0]
  def change
    add_column :onboard_on_rails_completions, :matched_urls, :jsonb, null: false, default: {}
  end
end
