class AdminMailer < ActionMailer::Base
  default :from => "no-reply@reservations.app"
  
  def notes_reservation_notification(notes_reservations_out, notes_reservations_in)
    @app_configs = AppConfig.first
    @notes_reservations_out = notes_reservations_out
    @notes_reservations_in = notes_reservations_in
    mail(:to => @app_configs.admin_email, :subject => "Checked out [Reservation] Notes for " + (Date.yesterday.midnight).strftime('%m/%d/%y'))
  end

  
end
