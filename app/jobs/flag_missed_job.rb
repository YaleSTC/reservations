# frozen_string_literal: true
class FlagMissedJob < ReservationJob
  private

  def type
    'newly missed'
  end

  def new_missed
    collection(:newly_missed)
  end

  def prep_collection
    new_missed
  end

  def run
    new_missed.each do |res|
      log_flag res
      update res
    end
  end

  def log_flag(res)
    Rails.logger.info "Flagging reservation #{res.id} as missed"
  end

  def update(res)
    res.update_attributes(status: 'missed')
  end
end
