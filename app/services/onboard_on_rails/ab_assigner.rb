require "digest"

module OnboardOnRails
  class AbAssigner
    def self.assign_group(user_id:, tour:, groups: nil)
      return nil if tour.ab_test_id.blank?

      groups ||= OnboardOnRails::Tour
        .where(ab_test_id: tour.ab_test_id)
        .distinct
        .pluck(:ab_test_group)
        .compact

      return nil if groups.empty?

      hash = Digest::SHA256.hexdigest("#{user_id}-#{tour.ab_test_id}")
      index = hash.to_i(16) % groups.size
      groups.sort[index]
    end
  end
end
