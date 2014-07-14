module ReservationScopes
  scope :recent, order('start_date, due_date, reserver_id')
  scope :user_sort, order('reserver_id')
  scope :reserved, lambda { where("checked_out IS NULL and checked_in IS NULL and due_date >= ? and (approval_status = ? or approval_status = ?)", Time.now.midnight.utc, 'auto', 'approved').recent}
  scope :checked_out, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date >=  ?", Time.now.midnight.utc).recent }
  scope :checked_out_today, lambda { where("checked_out >= ? and checked_in IS NULL", Time.now.midnight.utc).recent } # shouldn't this just check checked_out = today?
  scope :checked_out_previous, lambda { where("checked_out < ? and checked_in IS NULL and due_date <= ?", Time.now.midnight.utc, Date.tomorrow.midnight.utc).recent }
  scope :overdue, lambda { where("checked_out IS NOT NULL and checked_in IS NULL and due_date < ?", Time.now.midnight.utc ).recent }
  scope :returned, where("checked_in IS NOT NULL and checked_out IS NOT NULL")
  scope :returned_on_time, where("checked_in IS NOT NULL and checked_out IS NOT NULL and due_date >= checked_in").recent
  scope :returned_overdue, where("checked_in IS NOT NULL and checked_out IS NOT NULL and due_date < checked_in").recent
  scope :not_returned, where("checked_in IS NULL and (approval_status = ? or approval_status = ?)", 'auto', 'approved').recent # called in the equipment_model model
  scope :missed, lambda {where("checked_out IS NULL and checked_in IS NULL and due_date < ? and (approval_status = ? OR approval_status = ?)", Time.now.midnight.utc, 'auto', 'approved').recent}
  scope :upcoming, lambda {where("checked_out IS NULL and checked_in IS NULL and start_date = ? and due_date > ? and (approval_status = ? or approval_status = ?)", Time.now.midnight.utc, Time.now.midnight.utc, 'auto', 'approved').user_sort }
  scope :starts_on_days, lambda {|start_date, end_date|  where(start_date: start_date..end_date)}
  scope :reserved_on_date, lambda {|date|  where("start_date <= ? and due_date >= ? and (approval_status = ? or approval_status = ?)", date.to_time.utc, date.to_time.utc, 'auto', 'approved')}
  scope :for_eq_model, lambda { |eq_model| where(equipment_model_id: eq_model.id) } # by default includes all reservations ever. limit e.g. checked_out via other scopes
  scope :active, where("checked_in IS NULL and (approval_status = ? OR approval_status = ?)", 'auto', 'approved') # anything that's been reserved but not returned (i.e. pending, checked out, or overdue)
  scope :active_or_requested, lambda {where("checked_in IS NULL and approval_status != ?", 'denied')}
  scope :notes_unsent, where(notes_unsent: true)
  scope :requested, lambda {where("start_date >= ? and approval_status = ?", Time.now.midnight.utc, 'requested')}
  scope :approved_requests, lambda {where("approval_status = ?", 'approved')}
  scope :denied_requests, lambda {where("approval_status = ?", 'denied')}
  scope :missed_requests, lambda {where("approval_status = ? and start_date < ?", 'requested', Time.now.midnight.utc)}

  scope :for_reserver, lambda { |reserver| where(reserver_id: reserver) }
  scope :reserved_in_date_range, lambda { |start_date, end_date|
    where("start_date < ? and due_date > ? and (approval_status = ? or approval_status = ?)", end_date, start_date, 'auto', 'approved') }
  scope :overlaps_with_date, lambda{ |date| where("start_date <= ? and due_date >= ?",date.to_datetime,date.to_datetime) }
end


