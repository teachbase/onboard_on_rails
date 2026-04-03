module OnboardOnRails
  module Concerns
    module SegmentEvaluator
      extend ActiveSupport::Concern

      def matches_segment?(user_attributes)
        rules = segment_rules
        return true if rules.blank? || rules["conditions"].blank?

        conditions = rules["conditions"]
        logic = rules.fetch("logic", "and")

        if logic == "or"
          conditions.any? { |c| evaluate_condition(c, user_attributes) }
        else
          conditions.all? { |c| evaluate_condition(c, user_attributes) }
        end
      end

      private

      def evaluate_condition(condition, user_attributes)
        attr_name = condition["attribute"]
        operator = condition["operator"]
        expected = condition["value"]
        actual = user_attributes[attr_name.to_sym]

        return false if actual.nil?

        case operator
        when "eq" then actual.to_s == expected.to_s
        when "not_eq" then actual.to_s != expected.to_s
        when "in" then Array(expected).map(&:to_s).include?(actual.to_s)
        when "not_in" then !Array(expected).map(&:to_s).include?(actual.to_s)
        when "gt" then actual.to_s > expected.to_s
        when "lt" then actual.to_s < expected.to_s
        when "gte" then actual.to_s >= expected.to_s
        when "lte" then actual.to_s <= expected.to_s
        else false
        end
      end
    end
  end
end
