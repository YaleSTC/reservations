# frozen_string_literal: true
class EmailCheckoutReminderJob < ReservationJob
  include EmailJobHelper

  private

  def enabled
    AppConfig.check :upcoming_checkout_email_active?
  end

  def type
    'starting today'
  end

  def run
    upcoming_reservations.each do |res|
      log_email res
      send_email res
    end
  end

  def upcoming_reservations
    collection(:upcoming)
  end

  def prep_collection
    upcoming_reservations
  end
end
