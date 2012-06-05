class UserMailer < ActionMailer::Base
  default :from => "no-reply@reservations.app", :reply_to => Settings.admin_email

    def upcoming_checkout_notification(reservation)
      @reservation => reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] Reminder: equipment checkout")
    end
    
    def upcoming_checkin_notification(reservation)
      @reservation => reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] Reminder: equipment check in")
    end    
    
    def overdue_checkout_notification(reservation)
      @reservation => reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] OVERDUE: equipment checkout")
    end

    def overdue_checkin_notification(reservation)
      @reservation => reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] OVERDUE: equipment checkin")
    end  

    def warning_missing_equipment_notification(reservation)
      @reservation => reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] WARNING: missing equipment")
    end



end
