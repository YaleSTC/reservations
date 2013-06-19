class BlackOut < ActiveRecord::Base

  belongs_to :equipment_model
  attr_accessible :start_date, :end_date, :notice, :equipment_model_id, :black_out_type, :created_by, :set_id

  attr_accessor :days # needed for days of the week checkboxes in new_recurring

  validates :notice,
            :start_date,
            :equipment_model_id,
            :black_out_type,
            :end_date, :presence => true

  def self.black_outs_on_date(date) # Returns the black_out object that blacks out the day if the day is blacked out. Otherwise, returns nil.
    black_outs = []
    BlackOut.all.each do |black_out|
      if ((black_out.start_date..black_out.end_date).cover?(date.to_date))
        black_outs << black_out
      end
    end
    black_outs
  end

  def self.hard_backout_exists_on_date(date)
    black_outs = self.black_outs_on_date(date)
    if black_outs && black_outs.map(&:black_out_type).include?('hard')
      return true
    else
      return false
    end
  end

  def self.create_black_out_set(params_hash)
    #generate a unique id for this blackout date set, make sure that nil reads as 0 for the first blackout
    params_hash[:set_id] = BlackOut.last.id.to_i + 1

    # create an array of individual black out dates to include in set
    individual_dates = []
    date_range = params_hash[:start_date]..params_hash[:end_date]
    date_range.each do |date|
      if params_hash[:days].include?(date.wday.to_s) # because it's passed as a string
        individual_dates << date
      end
    end
    # save an individual blackout on each date
    return create_individual_black_outs_for_set(individual_dates, params_hash)
  end

  private
    def self.create_individual_black_outs_for_set(individual_dates, params_hash)
      successful_save = false
      individual_dates.each do |date|
        # create and save
        @black_out = BlackOut.new(params_hash)
        @black_out.start_date = date
        @black_out.end_date = date
        successful_save = @black_out.save
      end

      # return the error message unless a successful save was achieved
      unless successful_save
        return 'The combination of days and dates chosen did not produce any valid blackout dates. Please change your selection and try again.'
      end
    end

end

