class Announcement < ActiveRecord::Base
    validates :message,
            :ends_at,
            :starts_at, :presence => true
    validate :validate_end_date_before_start_date

  def self.current(hidden_ids = nil)
      result = where("starts_at <= :now and ends_at >= :now", now: Time.zone.now)
      result = result.where("id not in (?)", hidden_ids) if hidden_ids.present?
      result
  end

  def validate_end_date_before_start_date
    if ends_at && starts_at
      errors.add(:ends_at, "Start date must be before end date.") if ends_at < starts_at
    end
  end


end
