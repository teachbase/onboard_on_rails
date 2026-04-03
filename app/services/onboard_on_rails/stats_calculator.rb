module OnboardOnRails
  class StatsCalculator
    def initialize(tour)
      @tour = tour
    end

    def summary
      completions = @tour.completions
      total = completions.count
      completed = completions.completed.count
      dismissed = completions.dismissed.count
      {
        total_started: total,
        completed: completed,
        dismissed: dismissed,
        in_progress: total - completed - dismissed,
        completion_rate: total > 0 ? (completed.to_f / total * 100).round(1) : 0
      }
    end

    def drop_off_per_step
      @tour.steps.order(:position).map do |step|
        dropped = @tour.completions.where(step: step).where(status: %w[dismissed]).count
        { step_id: step.id, title: step.title, position: step.position, dropped: dropped }
      end
    end

    def ab_breakdown
      return [] if @tour.ab_test_id.blank?
      @tour.completions.group(:ab_group).select(
        "ab_group", "COUNT(*) as total",
        "COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count"
      ).map do |row|
        { group: row.ab_group, total: row.total, completed: row.completed_count,
          rate: row.total > 0 ? (row.completed_count.to_f / row.total * 100).round(1) : 0 }
      end
    end
  end
end
