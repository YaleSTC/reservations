class UserMailer < ActionMailer::Base
  # Workaround so that RSpec start-up doesn't fail. TODO: Have RSpec initialize AppConfig with configuration.
  unless (AppConfig.first.nil?)
    default from: AppConfig.first.admin_email, cc: AppConfig.first.admin_email
  else
    default from: 'no-reply@reservations.app'
  end

  def checkin_receipt(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservations] Your equipment return receipt")
  end

  def checkout_receipt(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservations] Your equipment checkout receipt")
  end

  def missed_reservation_deleted_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservations] Reservation Deleted (Missed Checkout Deadline)")
  end

  def overdue_checkin_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservations] OVERDUE: equipment checkin")
  end

  def overdue_checked_in_fine(overdue_checked_in)
    set_app_config
    @overdue_checked_in = overdue_checked_in
    mail(to: overdue_checked_in.reserver.email, subject: "[Reservations] Overdue equipment fine")
  end

  def reservation_confirmation(complete_reservation)
    set_app_config
    @complete_reservation = complete_reservation
    mail(to: complete_reservation.first.reserver.email, subject: "[Reservations] Confirmation of your reservation")
  end

  def upcoming_checkin_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservations] Reminder: equipment check in")
  end

  def request_approved_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservations] Reservation request approved!")
  end

  def request_denied_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservations] Reservation request denied")
  end

  private

  def set_app_config
    @app_configs ||= AppConfig.first
  end


end
