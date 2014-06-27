class Blackout < ActiveRecord::Base

  belongs_to :equipment_model
  attr_accessible :start_date, :end_date, :notice, :equipment_model_id, :blackout_type, :created_by, :set_id

  attr_accessor :days # needed for days of the week checkboxes in new_recurring

  validates :notice,
            :start_date,
            :equipment_model_id,
            :blackout_type,
            :end_date, presence: true

  validate :validate_end_date_before_start_date
  # this only matters if a user tries to inject into params because the datepicker
  # doesn't allow form submission of invalid dates

  def self.blackouts_on_date(date) # Returns the blackout object that blacks out the day if the day is blacked out. Otherwise, returns nil.
    blackouts = []
    Blackout.all.each do |blackout|
      if ((blackout.start_date..blackout.end_date).cover?(date.to_date))
        blackouts << blackout
      end
    end
    blackouts
  end

  #TODO: fix typo here and everywhere that this method is called. While at it, put a space in blackout since that's
  # it is everywhere else.
  def self.hard_blackout_exists_on_date(date)
    blackouts = self.blackouts_on_date(date)
    if blackouts && blackouts.map(&:blackout_type).include?('hard')
      return true
    else
      return false
    end
  end

  def self.create_blackout_set(params_hash)
    #generate a unique id for this blackout date set, make sure that nil reads as 0 for the first blackout
    last_blackout = Blackout.last
    params_hash[:set_id] = last_blackout ? (last_blackout.id.to_i + 1) : 0

    # create an array of individual black out dates to include in set
    individual_dates = []
    date_range = params_hash[:start_date].to_date..params_hash[:end_date].to_date
    date_range.each do |date|
      if params_hash[:days].include?(date.wday.to_s) # because it's passed as a string
        individual_dates << date
      end
    end
    # save an individual blackout on each date
    return create_individual_blackouts_for_set(individual_dates, params_hash)
  end

  private
    def self.create_individual_blackouts_for_set(individual_dates, params_hash)
      successful_save = false
      individual_dates.each do |date|
        # create and save
        @blackout = Blackout.new(params_hash)
        @blackout.start_date = date
        @blackout.end_date = date
        successful_save = @blackout.save
      end

      # return the error message unless a successful save was achieved
      unless successful_save
        return 'The combination of days and dates chosen did not produce any valid blackout dates. Please change your selection and try again.'
      end
    end

    def validate_end_date_before_start_date
      if end_date && start_date
        errors.add(:end_date, "Start date must be before end date.") if end_date < start_date
      end
    end

  # end private methods
end

