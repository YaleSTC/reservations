# frozen_string_literal: true
class FlagOverdueJob < ReservationJob
  private

  def type
    'newly overdue'
  end

  def new_overdue
    collection(:newly_overdue)
  end

  def prep_collection
    new_overdue
  end

  def run
    new_overdue.each do |res|
      log_flag res
      update res
    end
  end

  def log_flag(res)
    Rails.logger.info "Flagging reservation #{res.id} as overdue"
  end

  def update(res)
    res.update_attributes(overdue: true)
  end
end
