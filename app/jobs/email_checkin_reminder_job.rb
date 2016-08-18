# frozen_string_literal: true
class EmailCheckinReminderJob < ReservationJob
  include EmailJobHelper

  private

  def enabled
    AppConfig.check :upcoming_checkin_email_active?
  end

  def type
    'due today'
  end

  def run
    upcoming_reservations.each do |res|
      log_email res
      send_email res
    end
  end

  def upcoming_reservations
    collection(:due_today)
  end

  def prep_collection
    upcoming_reservations
  end
end
