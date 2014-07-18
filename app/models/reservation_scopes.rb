module ReservationScopes
  def self.included(base)
    base.class_eval do
      scope :recent, order('start_date, due_date, reserver_id')
      scope :user_sort, order('reserver_id')
      scope :finalized, lambda { where("approval_status = ? OR approval_status = ?",'auto','approved') }
      scope :not_returned, where("checked_in IS NULL").finalized # called in the equipment_model model
      scope :untouched, where("checked_out IS NULL").not_returned

      scope :reserved, lambda { where("due_date >= ?", Time.now.midnight.utc).untouched.recent }
      scope :checked_out, where("checked_out IS NOT NULL").not_returned.recent
      scope :checked_out_today, lambda { where("checked_out >= ? and checked_out <= ?", Date.today.to_datetime, Date.tomorrow.to_datetime).not_returned.recent }
      scope :checked_out_previous, lambda { where("checked_out < ? and due_date <= ?", Time.now.midnight.utc, Date.tomorrow.midnight.utc).not_returned.recent }
      scope :overdue, lambda { where("due_date < ?", Time.now.midnight.utc).not_returned }
      scope :returned, where("checked_in IS NOT NULL and checked_out IS NOT NULL").recent
      scope :returned_overdue, where("due_date < checked_in").returned
      scope :missed, lambda { where("due_date < ?", Time.now.midnight.utc).untouched.recent }
      scope :upcoming, lambda { where("start_date = ?", Time.now.midnight.utc).reserved.user_sort }
      scope :starts_on_days, lambda { |start_date, end_date|  where(start_date: start_date..end_date) }
      scope :reserved_on_date, lambda { |date|  where("start_date <= ? and due_date >= ?", date.to_time.utc, date.to_time.utc).finalized }
      scope :for_eq_model, lambda { |eq_model| where(equipment_model_id: eq_model.id).finalized }
      scope :active, not_returned
      scope :active_or_requested, lambda { where("checked_in IS NULL and approval_status != ?", 'denied').recent }
      scope :notes_unsent, where(notes_unsent: true)
      scope :requested, lambda { where("start_date >= ? and approval_status = ?", Time.now.midnight.utc, 'requested').recent }
      scope :approved_requests, lambda { where("approval_status = ?", 'approved').recent }
      scope :denied_requests, lambda { where("approval_status = ?", 'denied').recent }
      scope :missed_requests, lambda { where("approval_status = ? and start_date < ?", 'requested', Time.now.midnight.utc).recent }

      scope :for_reserver, lambda { |reserver| where(reserver_id: reserver) }
      scope :reserved_in_date_range, lambda { |start_date, end_date| where("start_date < ? and due_date > ?", end_date, start_date).finalized }
      scope :overlaps_with_date, lambda{ |date| where("start_date <= ? and due_date >= ?", date.to_datetime, date.to_datetime) }
    end
  end
end


