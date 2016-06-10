# frozen_string_literal: true
class EmailMissedReservationsJob < ReservationJob
  include EmailJobHelper

  private

  def enabled
    AppConfig.check :send_notifications_for_deleted_missed_reservations
  end

  def type
    'missed'
  end

  def run
    missed_reservations.each do |res|
      log_email res
      send_email res
      update res
    end
  end

  def update(res)
    res.flag(:missed_email_sent)
    res.save!
  end

  def missed_reservations
    collection(:missed_not_emailed)
  end

  def prep_collection
    missed_reservations
  end
end
