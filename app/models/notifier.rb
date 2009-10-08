class Notifier < ActionMailer::Base
  
  def reminder_notification(reservation)
    recipients reservation.reserver.email_address
    #bcc        ["bcc@example.com", "Order Watcher <watcher@example.com>"] #adminCC?
    from       "no-reply@reservations.app"
    subject    "[Reservation] Reminder: reservation pickup tomorrow"
    body       :reservation => reservation
  end

end
