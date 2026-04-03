module OnboardOnRails
  module Concerns
    module UrlMatchable
      extend ActiveSupport::Concern

      def matches_url?(url)
        patterns = url_pattern.is_a?(Array) ? url_pattern : [url_pattern]
        return true if patterns.empty?

        patterns.any? { |pattern| url_matches_pattern?(url, pattern.to_s) }
      end

      private

      def url_matches_pattern?(url, pattern)
        return true if pattern.blank?

        if pattern.include?("\\")
          Regexp.new("\\A#{pattern}\\z").match?(url)
        else
          regex = glob_to_regex(pattern)
          regex.match?(url)
        end
      end

      def glob_to_regex(glob)
        escaped = Regexp.escape(glob)
        escaped = escaped.gsub("\\*\\*", "DOUBLE_STAR")
        escaped = escaped.gsub("\\*", "[^/]*")
        escaped = escaped.gsub("DOUBLE_STAR", ".*")
        Regexp.new("\\A#{escaped}\\z")
      end
    end
  end
end
