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
        when "eq"           then actual.to_s == expected.to_s
        when "not_eq"       then actual.to_s != expected.to_s
        when "in"           then normalize_list(expected).include?(actual.to_s)
        when "not_in"       then !normalize_list(expected).include?(actual.to_s)
        when "gt"           then actual.to_f > expected.to_f
        when "lt"           then actual.to_f < expected.to_f
        when "gte"          then actual.to_f >= expected.to_f
        when "lte"          then actual.to_f <= expected.to_f
        when "starts_with"  then actual.to_s.start_with?(expected.to_s)
        when "ends_with"    then actual.to_s.end_with?(expected.to_s)
        when "contains"     then actual.to_s.include?(expected.to_s)
        when "not_contains" then !actual.to_s.include?(expected.to_s)
        when "matches"
          begin
            Timeout.timeout(1) { actual.to_s.match?(Regexp.new(expected.to_s)) }
          rescue RegexpError, Timeout::Error
            false
          end
        when "length_gt"    then actual.to_s.length > expected.to_i
        when "length_lt"    then actual.to_s.length < expected.to_i
        else false
        end
      end

      def normalize_list(value)
        case value
        when Array then value.map { |v| v.to_s.strip }
        when String then value.split(",").map(&:strip)
        else [value.to_s]
        end
      end
    end
  end
end
