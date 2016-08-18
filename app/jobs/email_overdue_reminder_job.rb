# frozen_string_literal: true
class EmailOverdueReminderJob < ReservationJob
  include EmailJobHelper

  private

  def enabled
    AppConfig.check :overdue_checkin_email_active?
  end

  def type
    'overdue'
  end

  def run
    overdue_reservations.each do |res|
      log_email res
      send_email res
    end
  end

  def overdue_reservations
    collection(:overdue)
  end

  def prep_collection
    overdue_reservations
  end
end
