class UserMailer < ActionMailer::Base
  # Workaround so that RSpec start-up doesn't fail. TODO: Have RSpec initialize AppConfig with configuration.
  unless (AppConfig.first.nil?)
    default from: AppConfig.first.admin_email, cc: AppConfig.first.admin_email
  end

  def checkin_receipt(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservation] Your equipment return receipt")
  end

  def checkout_receipt(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservation] Your equipment checkout receipt")
  end  

  def missed_reservation_deleted_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservation] Reservation Deleted (Missed Checkout Deadline)")
  end  

  def overdue_checkin_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservation] OVERDUE: equipment checkin")
  end  

  def reservation_confirmation(complete_reservation)
    set_app_config
    @complete_reservation = complete_reservation
    mail(to: complete_reservation.first.reserver.email, subject: "[Reservation] Confirmation of your reservation")
  end

  def upcoming_checkin_notification(reservation)
    set_app_config
    @reservation = reservation
    mail(to: reservation.reserver.email, subject: "[Reservation] Reminder: equipment check in")
  end    
  
  private

  def set_app_config
    @app_configs ||= AppConfig.first
  end


end
