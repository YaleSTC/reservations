class RemoveApprovalStatusFromReservation < ActiveRecord::Migration
  def change
    Reservation.transaction do
      Reservation.all.each do |res|
        if res.approval_status == 'approved'
          res.flag(:request)
        elsif res.approval_status == 'missed_and_emailed'
          res.flag(:missed_email_sent)
        end

        if res.checked_in 
          res.status = 'returned'
          if res.checked_in > (res.due_date + 1.day)
            res.overdue = true
          end
          if res.notes.try(:include?, 'Archived')
            res.status = 'archived'
          end
        elsif res.checked_out
          res.status = 'checked_out'
          if (res.due_date + 1.day) < Time.zone.today
            res.overdue = true
          end
        elsif res.start_date < Time.zone.today
          res.status = 'missed'
        elsif res.approval_status == 'requested'
          res.flag(:request)
          res.status = 'requested'
        elsif res.approval_status == 'denied'
          res.flag(:request)
          res.status = 'denied'
        elsif 'approved auto'.include? res.approval_status
          res.status = 'reserved'
        else
          # catch any unusual reservations
          res.flag(:request)
          res.status = 'requested'
        end
        res.save!
      end
    end

    remove_column :reservations, :approval_status, :string
  end
end
