# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
class Reservation < ActiveRecord::Base
  include Linkable
  include ReservationValidations

  belongs_to :equipment_model
  belongs_to :equipment_item
  belongs_to :reserver, class_name: 'User'
  belongs_to :checkout_handler, class_name: 'User'
  belongs_to :checkin_handler, class_name: 'User'

  validates :equipment_model, :start_date, :due_date, presence: true
  validates_each :reserver do |record, attr, value|
    record.errors.add(attr, 'cannot be a guest') if value.role == 'guest'
  end
  validate :start_date_before_due_date
  validate :matched_item_and_model
  validate :check_status
  validate :status_final_state
  validate :not_in_past, :available, :check_banned, on: :create

  # conditional counter cache for overdue reservations
  after_update :increment_cache, if: :checked_out?
  after_update :decrement_cache, if: :overdue

  # make counter cache update on create
  # should only ever get called in the test suite
  after_create :test_cache, if: :overdue

  # correctly update the overdue flag if necessary
  before_save :update_overdue, if: :checked_out?

  nilify_blanks only: [:notes]

  # see https://robots.thoughtbot.com/whats-new-in-edge-rails-active-record-enum
  enum status: %w(requested reserved denied checked_out missed returned
                  archived)

  # valid bitmask flags
  # set by reservation |= FLAGS[:flag]
  # check by reservation & FLAGS[:flag]
  #   = 0 when false
  #   > 0 when true
  # query by where('flags & ? > 0', FLAGS[:flag])
  # or where('flags & ? = 0', FLAGS[:flag]) for not flagged
  FLAGS = { request: (1 << 1), broken: (1 << 2), lost: (1 << 3),
            fined: (1 << 4), missed_email_sent: (1 << 5),
            expired: (1 << 6) }.freeze

  ## Scopes ##
  # general scopes
  default_scope { order('start_date, due_date, reserver_id') }
  scope :for_eq_model, ->(em_id) { where(equipment_model_id: em_id) }
  scope :for_reserver, ->(reserver_id) { where(reserver_id: reserver_id) }

  # flag scopes
  scope :flagged, ->(flag) { where('flags & ? > 0', FLAGS[flag]) }
  scope :not_flagged, ->(flag) { where('flags & ? = 0', FLAGS[flag]) }

  # basic status scopes
  scope :active, lambda {
    where(status: Reservation.statuses.values_at(*%w(reserved checked_out)))
  }
  scope :finalized, lambda {
    where.not(status: Reservation.statuses.values_at(*%w(denied requested)))
  }
  scope :active_or_requested, lambda {
    where(status: Reservation.statuses.values_at(
      *%w(requested reserved checked_out)
    ))
  }

  # overdue / request scopes
  scope :overdue, ->() { where(overdue: true).checked_out }
  scope :not_overdue, ->() { where(overdue: false) }
  scope :returned_on_time, ->() { where(overdue: false).returned }
  scope :returned_overdue, ->() { where(overdue: true).returned }
  scope :approved_requests, ->() { flagged(:request).finalized }
  scope :missed_requests, ->() { past_date(:start_date).requested }

  # generalized date scopes (pass parameter as either a string or a symbol)
  scope :past_date, ->(param) { where("#{param} < ?", Time.zone.today) }
  scope :today_date, ->(param) { where(param.to_sym => Time.zone.today) }

  # basic date scopes
  scope :checked_out_today, ->() { today_date(:checked_out) }
  scope :checked_out_previous, ->() { past_date(:checked_out) }
  scope :due_today, ->() { today_date(:due_date).checked_out }

  # more complex / task-specific scopes
  scope :checkoutable, Reservations::CheckoutableQuery
  scope :for_cat, Reservations::ForCatQuery
  scope :future, Reservations::FutureQuery
  scope :notes_unsent, Reservations::NotesUnsentQuery
  scope :overlaps_with_date_range, Reservations::OverlapsWithDateRangeQuery
  scope :starts_on_days, Reservations::StartsOnDaysQuery
  scope :upcoming, Reservations::UpcomingQuery
  scope :consecutive_with, Reservations::ConsecutiveWithQuery

  # join Scopes
  scope :with_categories, lambda {
    joins(:equipment_model)
      .select('reservations.*, equipment_models.category_id as category_id')
  }

  # for status modifying jobs
  scope :missed_not_emailed, ->() { missed.not_flagged(:missed_email_sent) }
  scope :newly_missed, ->() { reserved.past_date(:start_date) }
  scope :newly_overdue, ->() { not_overdue.checked_out.past_date(:due_date) }

  def self.deletable_missed
    return Reservation.none if AppConfig.check(:res_exp_time, '').blank?
    threshold = Time.zone.today - AppConfig.get(:res_exp_time).days
    Reservation.missed.where('start_date < ?', threshold)
  end

  ## Class methods ##

  def self.completed_procedures(procedures)
    # convert the [{id=>value, id=>value}] input
    # to [id, id] format
    return [] if procedures.nil?
    procedures.collect do |key, val|
      key if val == '1'
    end
  end

  def self.unique_equipment_items?(reservations)
    item_ids = reservations.map(&:equipment_item_id)
    item_ids == item_ids.uniq
  end

  # Counts the number of reservations in source that overlap with the given date
  # If no date is given, defaults to today
  # If attrs are given, only counts the reservation if it has the
  # specified attributes
  def self.number_for(source, date: Time.zone.today, **attrs)
    source.to_a.count { |r| r.overlaps_with(date) && r.attrs?(attrs) }
  end

  # Same as number_for, just over a range of dates
  def self.number_for_date_range(source, date_range, **attrs)
    date_range.map { |d| Reservation.number_for(source, date: d, **attrs) }
  end

  ## Getter style instance methods ##

  def approved?
    flagged?(:request) && !%w(denied requested).include?(status)
  end

  def flagged?(flag)
    # checks to see if the given flag is set
    # you must pass the symbol for the flag
    flags & FLAGS[flag] > 0
  end

  # Generic method for checking if a reservation fits a hash of attributes
  # Stops checking attributes when it finds a false
  def attrs?(attrs)
    attrs.each { |k, v| return false unless send(k) == v }
    true
  end

  def overlaps_with(d)
    start_date <= d && due_date >= d
  end

  def flag(flag)
    self.flags |= FLAGS[flag]
  end

  def unflag(flag)
    self.flags - FLAGS[flag]
  end

  def expire!
    self.status = 'denied'
    flag(:expired)
    save
  end

  def human_status # rubocop:disable all
    if overdue
      if status == 'returned'
        'returned overdue'
      else
        'overdue'
      end
    elsif start_date == Time.zone.today && status == 'reserved'
      'starts today'
    elsif due_date == Time.zone.today && status == 'checked_out'
      'due today'
    else
      status
    end
  end

  # returns end of reservation, either checkin date (if returned), today (if
  # overdue), or due date otherwise
  def end_date
    return checked_in if checked_in
    return Time.zone.today if overdue
    due_date
  end

  def duration
    due_date - start_date + 1
  end

  def time_checked_out
    checked_in.to_date - checked_out.to_date + 1 if checked_out && checked_in
  end

  def late_fee
    return 0 unless overdue
    fee = equipment_model.late_fee * (end_date.to_date - due_date)
    if fee < 0
      fee = 0
    elsif equipment_model.late_fee_max > 0
      fee = [fee, equipment_model.late_fee_max].min
    end
    fee
  end

  def reserver
    User.find(reserver_id)
  rescue
    # if user's been deleted, return a dummy user
    User.new(first_name: 'Deleted',
             last_name: 'User',
             username: 'deleted',
             email: 'deleted.user@invalid.address',
             nickname: '',
             phone: '555-555-5555',
             affiliation: 'Deleted')
  end

  def fake_reserver_id # this is necessary for autocomplete! delete me not!
  end

  ## Instance method helper/misc  ##

  def find_renewal_date
    # determine the max renewal length for a given reservation
    # O(n) queries

    renew_extension = dup
    renew_extension.start_date = due_date + 1.day
    orig_due_date = due_date
    eq_model = equipment_model

    eq_model.maximum_renewal_length.downto(1).each do |r|
      renew_extension.due_date = orig_due_date + r.days
      return renew_extension.due_date if renew_extension.validate_renew.empty?
    end
    due_date
  end

  def eligible_for_renew? # rubocop:disable all
    # determines if a reservation is eligible for renewal, based on how many
    # days before the due date it is, the max number of times one is allowed
    # to renew, and other factors
    #

    # check some basic conditions
    return false if !checked_out? || overdue? || reserver.role == 'banned'
    return false unless equipment_model.maximum_renewal_length > 0
    return false unless equipment_model.num_available_on(due_date + 1.day) > 0

    self.times_renewed ||= 0

    return false if self.times_renewed >= equipment_model.maximum_renewal_times
    return false if (due_date - Time.zone.today).to_i >
                    equipment_model.maximum_renewal_days_before_due
    true
  end

  def to_cart
    temp_cart = Cart.new
    temp_cart.start_date = start_date
    temp_cart.due_date = due_date
    temp_cart.reserver_id = reserver_id
    temp_cart.items = { equipment_model_id => 1 }
    temp_cart
  end

  ## Instance methods that alter the status of a reservation ##

  def renew(user)
    # renew the reservation and return error messages if unsuccessful
    return 'Reservation not eligible for renewal' unless eligible_for_renew?
    self.due_date = find_renewal_date
    self.notes = notes.to_s + "\n\n### Renewed on "\
      "#{Time.zone.now.to_s(:long)} by #{user.md_link}\n\nThe new due date "\
      "is  #{due_date.to_s(:long)}."
    self.times_renewed += 1
    return 'Unable to update reservation dates.' unless save
    nil
  end

  def checkin(checkin_handler, procedures, new_notes)
    # Checks in a reservation with the given checkin handler
    # and hash of checkin procedures and any manually entered
    # notes from the checkin
    #
    # Returns the unsaved, checked in reservation

    self.checkin_handler = checkin_handler
    self.checked_in = Time.zone.now
    self.status = 'returned'

    # gather all the procedure texts that were not
    # checked, ie not included in the procedures hash
    incomplete_procedures = []
    procedures = Reservation.completed_procedures(procedures)
    equipment_model.checkin_procedures.each do |checkin_procedure|
      if procedures.exclude?(checkin_procedure.id.to_s)
        incomplete_procedures << checkin_procedure.step
      end
    end
    make_notes('Checked in', new_notes, incomplete_procedures, checkin_handler)

    if checked_in.to_date > due_date
      # equipment was overdue, send an email confirmation
      AdminMailer.overdue_checked_in_fine_admin(self).deliver_now
      UserMailer.reservation_status_update(self).deliver_now
    end

    self
  end

  def archive(archiver, note)
    # set the reservation as checked in if it has been checked out
    # used for emergency situations or when equipment is deactivated
    # to preserve database sanity (eg, equipment item is deactivated while
    # that reseration is checked out)
    # returns self
    if checked_in.nil?
      self.checked_in = Time.zone.now
      self.checked_out = Time.zone.now if checked_out.nil?
      self.notes = notes.to_s + "\n\n### Archived on "\
        "#{checked_in.to_s(:long)} by #{archiver.md_link}\n\n\n#### " \
        "Reason:\n#{note}\n\n#### The checkin and checkout dates may "\
        'reflect the archive date because the reservation was for a '\
        'nonexistent piece of equipment or otherwise problematic.'
      self.status = 'archived'
    end
    self
  end

  def checkout(eq_item, checkout_handler, procedures, new_notes)
    # checks out a reservation with the given equipment item, checkout handler
    # and a hash of checkout procedures and any manually entered
    # notes from the checkout.
    #
    # Returns the unsaved, checked out reservation

    self.checkout_handler = checkout_handler
    self.checked_out = Time.zone.now
    self.equipment_item_id = eq_item
    self.status = 'checked_out'

    incomplete_procedures = []
    procedures = Reservation.completed_procedures(procedures)
    equipment_model.checkout_procedures.each do |checkout_procedure|
      if procedures.exclude?(checkout_procedure.id.to_s)
        incomplete_procedures << checkout_procedure.step
      end
    end
    make_notes('Checked out', new_notes, incomplete_procedures,
               checkout_handler)
    self
  end

  def update(current_user, new_params, new_notes) # rubocop:disable all
    # updates a reservation and records changes in the notes
    #
    # takes the current user, the new params from the controller that have
    # been updated w/ a new equipment item, and the new notes (if any)
    assign_attributes(new_params)
    changes = self.changes
    new_notes = '' unless new_notes
    return self if new_notes.empty? && changes.empty?
    # write notes header
    header = "### Edited on #{Time.zone.now.to_s(:long)} by "\
      "#{current_user.md_link}\n"
    self.notes = notes ? notes + "\n\n" + header : header

    # add notes if they exist
    self.notes += "\n\n#### Notes:\n#{new_notes}" unless new_notes.empty?

    # record changes
    # rubocop:disable BlockNesting
    unless changes.empty?
      self.notes += "\n\n#### Changes:"
      changes.each do |param, diff|
        case param
        when 'reserver_id'
          name = 'Reserver'
          old_val = diff[0] ? User.find(diff[0]).md_link : 'nil'
          new_val = diff[1] ? User.find(diff[1]).md_link : 'nil'
        when 'start_date'
          name = 'Start Date'
          old_val = diff[0].to_s(:long)
          new_val = diff[1].to_s(:long)
        when 'due_date'
          name = 'Due Date'
          old_val = diff[0].to_s(:long)
          new_val = diff[1].to_s(:long)
          if checked_out?
            overdue_str = if overdue? && diff[1] >= Time.zone.today
                            "\nReservation marked as not overdue."
                          elsif !overdue? && diff[1] < Time.zone.today
                            "\nReservation marked as overdue."
                          end
          end
        when 'equipment_item_id'
          name = 'Item'
          old_val = diff[0] ? EquipmentItem.find(diff[0]).md_link : 'nil'
          new_val = diff[1] ? EquipmentItem.find(diff[1]).md_link : 'nil'
        end
        self.notes += "\n#{name} changed from " + old_val + ' to '\
          + new_val + '.' + overdue_str.to_s
      end
    end
    # rubocop:enable BlockNesting

    self.notes = self.notes.strip
    self
  end

  # rubocop:disable PerceivedComplexity
  def make_notes(procedure_verb, new_notes, incomplete_procedures,
                 current_user)
    # handles the reservation notes from the new notes
    #
    # takes the new notes and a string, 'checked in' or 'checked out' as the
    # procedure_kind

    # write notes header
    header = "### #{procedure_verb} on #{Time.zone.now.to_s(:long)} by "\
      "#{current_user.md_link}\n"
    self.notes = self.notes ? self.notes + "\n\n" + header : header

    # If no new notes and no missed procedures, set e-mail flag to false and
    # return
    if new_notes.empty? && incomplete_procedures.empty?
      self.notes += "\n\nAll procedures were performed!"
      self.notes_unsent = false
      return
    else
      self.notes_unsent = true
    end

    # add notes if they exist
    self.notes += "\n\n#### Notes:\n#{new_notes}" unless new_notes.empty?

    # record note procedure status
    if incomplete_procedures.empty?
      self.notes += "\n\nAll procedures were performed!"
    else
      self.notes += "\n\n#### The following procedures were not performed:\n"
      self.notes += markdown_listify(incomplete_procedures)
    end
    self.notes = self.notes.strip
  end
  # rubocop:enable PerceivedComplexity

  # returns a string where each item is begun with a '*'
  def markdown_listify(items)
    '* ' + items.join("\n* ")
  end

  def name
    "\##{id}"
  end

  private

  def update_overdue
    return true unless checked_out?
    if due_date < Time.zone.today
      self.overdue = true
    else
      # decrement the counter cache if we're changing overdue
      # check for id to make sure this is not a new, unsaved reservation
      # (only relevant in testing when overdue reservations are created)
      equipment_model.decrement(:overdue_count) if overdue && id && checked_out?
      self.overdue = false
    end
    true # so we don't halt the transaction if it's not overdue
  end

  # custom counter cache methods
  # keeps a count of how many actively overdue reservations there are for
  # every equipment model
  def increment_cache
    return true unless overdue && overdue_changed?
    # just made overdue
    equipment_model.increment(:overdue_count)
    true
  end

  def decrement_cache
    return true unless checked_in? && status_changed?
    # just checked in
    equipment_model.decrement(:overdue_count)
    true
  end

  # Only used when overdue reservations are created in the test suite
  def test_cache
    # check for id to make sure this is a new, unsaved reservation
    return true if checked_in? || id
    equipment_model.increment(:overdue_count)
    true
  end
end
