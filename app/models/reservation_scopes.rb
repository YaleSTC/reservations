module ReservationScopes
  def self.included(base)
    base.class_eval do
      scope :recent, lambda { order('start_date, due_date, reserver_id') }
      scope :user_sort, lambda { order('reserver_id') }
      scope :finalized, lambda { where("approval_status = ? OR approval_status = ?",'auto','approved') }
      scope :not_returned, lambda { where("checked_in IS NULL").finalized }# called in the equipment_model model
      scope :untouched, lambda { where("checked_out IS NULL").not_returned }
      scope :reserved, lambda { where("due_date >= ?", Time.zone.today.to_time).untouched.recent }
      scope :checked_out, lambda { where("checked_out IS NOT NULL").not_returned.recent }
      scope :checked_in, lambda { returned }
      scope :checked_out_today, lambda { where("checked_out >= ? and checked_out <= ?", Time.zone.today.to_time, Time.zone.today.to_time + 1.day).not_returned.recent }
      scope :checked_out_previous, lambda { where("checked_out < ? and due_date <= ?", Time.zone.today.to_time, Time.zone.today.to_time + 1.day).not_returned.recent }
      scope :overdue, lambda { where("due_date < ?", Time.zone.today.to_time).checked_out }
      scope :returned, lambda { where("checked_in IS NOT NULL and checked_out IS NOT NULL").recent }
      scope :returned_overdue, lambda { returned.select { |r| r.due_date < r.checked_in } }
      scope :returned_on_time, lambda { where("checked_in <= due_date").returned }
      scope :missed, lambda { where("due_date < ?", Time.zone.today.to_time).untouched.recent }
      scope :upcoming, lambda { where("start_date > ?", Time.zone.today.to_time).reserved.user_sort }
      scope :checkoutable, lambda { where("start_date <= ? and due_date < ?", Time.zone.today.to_time, Time.zone.today.to_time).reserved }
      scope :starts_on_days, lambda { |start_date, end_date|  where(start_date: start_date..end_date) }
      scope :reserved_on_date, lambda { |date|  where("start_date <= ? and due_date >= ?", Time.zone.parse(date.to_s), Time.zone.parse(date.to_s)).finalized }
      scope :for_eq_model, lambda { |eq_model| where(equipment_model_id: eq_model.id).finalized }
      scope :active, lambda { not_returned }
      scope :active_or_requested, lambda { where("checked_in IS NULL and approval_status != ?", 'denied').recent }
      scope :notes_unsent, lambda { where(notes_unsent: true) }
      scope :requested, lambda { where("start_date >= ? and approval_status = ?", Time.zone.today.to_time, 'requested').recent }
      scope :approved_requests, lambda { where("approval_status = ?", 'approved').recent }
      scope :denied_requests, lambda { where("approval_status = ?", 'denied').recent }
      scope :missed_requests, lambda { where("approval_status = ? and start_date < ?", 'requested', Time.zone.today.to_time).recent }
      scope :for_reserver, lambda { |reserver| where(reserver_id: reserver) }
      scope :reserved_in_date_range, lambda { |start_date, end_date| where("start_date <= ? and due_date >= ?", end_date, start_date).finalized }
      scope :overlaps_with_date, lambda { |date| where("start_date <= ? and due_date >= ?", Time.zone.parse(date.to_s), Time.zone.parse(date.to_s)) }
      scope :has_notes, lambda { where("notes IS NOT NULL") }
    end
  end
end


