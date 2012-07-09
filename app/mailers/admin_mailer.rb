class AdminMailer < ActionMailer::Base
  default :from => "no-reply@reservations.app"
  
  def notes_reservation_notification(notes_reservations)
    @notes_reservations = notes_reservations
    mail(:to => @app_configs.admin_email, :subject => "[Reservation] Notes for " + (Time.now - 86400).strftime('%m/%d/%y'))
  end
  
end
