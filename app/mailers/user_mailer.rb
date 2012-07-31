class UserMailer < ActionMailer::Base
 # default :from => "no-reply@reservations.app", :reply_to => @app_configs.admin_email

    def upcoming_checkout_notification(reservation)
      @reservation = reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] Reminder: equipment checkout")
    end
    
    def upcoming_checkin_notification(reservation)
      @reservation = reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] Reminder: equipment check in")
    end    
    
    def overdue_checkout_notification(reservation)
      @reservation = reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] OVERDUE: equipment checkout")
    end

    def overdue_checkin_notification(reservation)
      @reservation = reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] OVERDUE: equipment checkin")
    end  

    def warning_missing_equipment_notification(reservation)
      @reservation = reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] WARNING: missing equipment")
    end
    
    def reservation_confirmation(complete_reservation)
      @complete_reservation = complete_reservation
      mail(:to => complete_reservation.first.reserver.email, :subject => "[Reservation] Confirmation of your reservation")
    end
    
    def checkout_receipt(reservation)
      @reservation = reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] Your equipment checkout receipt")
    end
    
    def checkin_receipt(reservation)
      @reservation = reservation
      mail(:to => reservation.reserver.email, :subject => "[Reservation] Your equipment return receipt")
    end

end
