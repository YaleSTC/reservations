# frozen_string_literal: true

class Blackout < ApplicationRecord
  attr_accessor :days # needed for days of the week checkboxes in new_recurring

  validates :notice,
            :start_date,
            :blackout_type,
            :end_date, presence: true

  validate :validate_end_date_before_start_date
  # this only matters if a user tries to inject into params because the
  # datepicker doesn't allow form submission of invalid dates

  scope :active, ->() { where('end_date >= ?', Time.zone.today) }
  scope :for_date, lambda { |date|
    where('end_date >= ? and start_date <= ?', date, date)
  }
  scope :hard, ->() { where(blackout_type: 'hard') }
  scope :soft, ->() { where(blackout_type: 'soft') }

  def self.get_notices_for_date(date, type = :all)
    # get a string of all notices for a given date
    # default to all blackouts
    blackouts = if type == :soft
                  Blackout.soft.for_date(date)
                elsif type == :hard
                  Blackout.hard.for_date(date)
                else
                  Blackout.for_date(date)
                end
    messages = []
    blackouts.for_date(date).each do |b|
      messages << b.notice
    end
    messages.to_sentence
  end

  def self.create_blackout_set(params_hash, days) # rubocop:disable all
    # generate a unique id for this blackout date set, make sure that nil
    # reads as 0 for the first blackout
    last_blackout = Blackout.last
    params_hash[:set_id] = last_blackout ? (last_blackout.id.to_i + 1) : 0
    date_range =
      params_hash[:start_date].to_date..params_hash[:end_date].to_date

    # initialize arrays for query dates and blackout objects
    res_dates = []
    blackouts_tmp = []
    date_range.each do |date|
      # because it's passed as a string
      next unless days.include?(date.wday.to_s)
      @blackout = Blackout.new(params_hash)
      @blackout.start_date = date
      @blackout.end_date = date
      # save dates for conflict checking and blackout objects
      res_dates << DateTime.parse(date.to_s) # rubocop:disable TimeZone
      blackouts_tmp << @blackout
    end
    # check for conflicts
    res = Reservations::AffectedByRecurringBlackoutQuery.call(res_dates)
    if res.empty?
      # try to save all of the blackouts
      successful_save = nil
      blackouts_tmp.each do |blackout|
        successful_save = blackout.save
      end
    else
      # if conflicts exist, generate appropriate flash message
      msg = 'The following reservation(s) will be unable to be returned: '
      res.each do |res2|
        msg += "#{res2.md_link}, "
      end
      return msg[0, msg.length - 2] + '. Please update their due dates and '\
        'try again.'
    end

    invalid_dates_msg = 'The combination of days and dates chosen did not '\
      'produce any valid blackout dates. Please change your selection and try '\
      'again.'
    return invalid_dates_msg unless successful_save
  end

  private

  def validate_end_date_before_start_date
    return unless end_date && start_date && (end_date < start_date)
    errors.add(:end_date, 'Start date must be before end date.')
  end

  # end private methods
end
