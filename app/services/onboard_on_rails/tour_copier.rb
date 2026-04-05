module OnboardOnRails
  class TourCopier
    def self.call(original)
      new(original).call
    end

    def initialize(original)
      @original = original
    end

    def call
      new_tour = @original.dup
      new_tour.name = "#{@original.name} #{I18n.t('onboard_on_rails.admin.tours.copy_suffix')}"
      new_tour.status = "draft"

      ActiveRecord::Base.transaction do
        new_tour.save!

        @original.steps.order(:position).each do |step|
          new_step = step.dup
          new_step.tour = new_tour
          new_step.save!
        end
      end

      new_tour
    rescue ActiveRecord::RecordInvalid
      new_tour
    end
  end
end
