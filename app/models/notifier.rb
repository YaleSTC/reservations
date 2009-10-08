class Notifier < ActionMailer::Base
  
  def upcoming_checkout_notification(reservation)
    recipients reservation.reserver.email
    cc         Settings.admin_email
    from       "no-reply@reservations.app"
    subject    "[Reservation] Reminder: equipment checkout"
    body       :reservation => reservation
  end
  
  def upcoming_checkin_notification(reservation)
    recipients reservation.reserver.email
    cc         Settings.admin_email
    from       "no-reply@reservations.app"
    subject    "[Reservation] Reminder: equipment checkin"
    body       :reservation => reservation
  end
  
  def overdue_checkout_notification(reservation)
    recipients reservation.reserver.email
    cc         Settings.admin_email
    from       "no-reply@reservations.app"
    subject    "[Reservation] OVERDUE: equipment checkout"
    body       :reservation => reservation
  end
  
  def overdue_checkin_notification(reservation)
    recipients reservation.reserver.email
    cc         Settings.admin_email
    from       "no-reply@reservations.app"
    subject    "[Reservation] OVERDUE: equipment checkin"
    body       :reservation => reservation
  end
end
