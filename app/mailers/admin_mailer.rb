class AdminMailer < ActionMailer::Base
  default from: "no-reply@reservations.app"

  def notes_reservation_notification(notes_reservations_out, notes_reservations_in)
    @app_configs = AppConfig.first
    @notes_reservations_out = notes_reservations_out
    @notes_reservations_in = notes_reservations_in
    mail(to: @app_configs.admin_email, subject: "[Reservations] Notes for " + (Date.yesterday.midnight).strftime('%m/%d/%y'))
  end

  def overdue_checked_in_fine_admin(overdue_checked_in)
    @app_configs = AppConfig.first
    @overdue_checked_in = overdue_checked_in
    mail(to: @app_configs.admin_email, subject: "[Reservations] Overdue equipment fine")
  end

  def request_filed(request)
    @app_configs = AppConfig.first
    @reservation = request
    mail(to: @app_configs.admin_email, subject: "[Reservations] Request submitted")
  end
end
