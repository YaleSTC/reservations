class AdminMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  default from: 'no-reply@reservations.app'

  def notes_reservation_notification(notes_reservations_out,
                                     notes_reservations_in)
    @notes_reservations_out = notes_reservations_out
    @notes_reservations_in = notes_reservations_in
    mail(to: AppConfig.get(:admin_email),
         subject: '[Reservations] Notes for '\
           + (Time.zone.today - 1.day).strftime('%m/%d/%y'))
  end

  def overdue_checked_in_fine_admin(overdue_checked_in)
    return if overdue_checked_in.equipment_model.late_fee == 0
    @overdue_checked_in = overdue_checked_in
    mail(to: AppConfig.get(:admin_email),
         subject: '[Reservations] Overdue equipment fine')
  end

  def request_filed(request)
    @reservation = request
    mail(to: AppConfig.get(:admin_email),
         subject: '[Reservations] Request submitted')
  end
end
