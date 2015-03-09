# rubocop:disable ClassLength
class Reservation < ActiveRecord::Base
  include ReservationValidations
  include ReservationScopes
  include Routing

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
  validate :not_in_past, :available, :check_banned, on: :create

  nilify_blanks only: [:notes]

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

  def self.number_for_model_on_date(date, model_id, source)
    # count the number of reservations that overlaps a date within
    # a given array of source reservations and that matches
    # a specific model id
    number_for(date, model_id, source, :equipment_model_id)
  end

  def self.number_for_category_on_date(date, category_id, reservations)
    number_for(date, category_id, reservations, :category_id)
  end

  def self.number_for(date, value, source, property)
    count = 0
    source.each do |r|
      if r.start_date <= date && r.due_date >= date &&
         r.send(property) == value
        count += 1
      end
    end
    count
  end

  def self.number_overdue_for_eq_model(model_id, reservations)
    # count the number of overdue reservations for a given
    # eq model out of an array of source reservations
    #
    # used in rendering the catalog in order to save db queries
    #
    # 0 queries
    count = 0
    reservations.each do |r|
      count += 1 if r.status == 'overdue' && r.equipment_model_id == model_id
    end
    count
  end

  ## Getter style instance methods ##

  def status # rubocop:disable CyclomaticComplexity, PerceivedComplexity
    return if due_date.nil?
    if checked_out.nil?
      if approval_status == 'auto' || approval_status == 'approved'
        due_date >= Time.zone.today ? 'reserved' : 'missed'
      elsif approval_status
        approval_status
      else
        # just in case an admin does something absurd in the database?
        '?'
      end
    elsif checked_in.nil?
      due_date < Time.zone.today ? 'overdue' : 'checked out'
    else
      due_date < checked_in.to_date ? 'returned overdue' : 'returned on time'
    end
  end

  def duration
    due_date - start_date + 1
  end

  def time_checked_out
    checked_in.to_date - checked_out.to_date + 1 if checked_out && checked_in
  end

  def late_fee
    equipment_model.late_fee.to_f
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

  def eligible_for_renew?
    # determines if a reservation is eligible for renewal, based on how many
    # days before the due date it is and the max number of times one is
    # allowed to renew
    #
    return false if reserver.role == 'banned'

    self.times_renewed ||= 0

    # you can't renew a checked in reservation, or one without an equipment
    # model
    return false if checked_in || equipment_item.nil?

    max_renewal_times = equipment_model.maximum_renewal_times

    max_renewal_days = equipment_model.maximum_renewal_days_before_due
    ((due_date - Time.zone.today).to_i < max_renewal_days) &&
      (self.times_renewed < max_renewal_times) &&
      equipment_model.maximum_renewal_length > 0
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
    unless self.eligible_for_renew?
      return 'Reservation not eligible for renewal'
    end
    self.due_date = find_renewal_date
    self.notes = "#{notes}" + "\n\n### Renewed on "\
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
    # update equipment item notes
    equipment_item.make_reservation_notes('checked in', self,
                                          checkin_handler, new_notes,
                                          checked_in)

    if checked_in.to_date > due_date
      # equipment was overdue, send an email confirmation
      AdminMailer.overdue_checked_in_fine_admin(self).deliver
      UserMailer.reservation_status_update(self).deliver
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
      # archive equipment item if checked out
      if equipment_item
        equipment_item.make_reservation_notes('archived', self, archiver,
                                              "#{note}", checked_in)
      end
      self.notes = notes.to_s + "\n\n### Archived on "\
        "#{checked_in.to_s(:long)} by #{archiver.md_link}\n\n\n#### " \
        "Reason:\n#{note}\n\n#### The checkin and checkout dates may "\
        'reflect the archive date because the reservation was for a '\
        'nonexistent piece of equipment or otherwise problematic.'
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

    incomplete_procedures = []
    procedures = Reservation.completed_procedures(procedures)
    equipment_model.checkout_procedures.each do |checkout_procedure|
      if procedures.exclude?(checkout_procedure.id.to_s)
        incomplete_procedures << checkout_procedure.step
      end
    end
    make_notes('Checked out', new_notes, incomplete_procedures,
               checkout_handler)
    # update equipment item notes
    equipment_item.make_reservation_notes('checked out', self,
                                          checkout_handler, new_notes,
                                          checked_out)
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
    if new_notes.empty? && changes.empty?
      return self
    else
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
          when 'equipment_item_id'
            name = 'Item'
            old_val = diff[0] ? EquipmentItem.find(diff[0]).md_link : 'nil'
            new_val = diff[1] ? EquipmentItem.find(diff[1]).md_link : 'nil'
          end
          self.notes += "\n#{name} changed from " + old_val + ' to '\
            + new_val + '.'
        end
      end
      # rubocop:enable BlockNesting

      self.notes = self.notes.strip
      self
    end
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

  def md_link
    "[res. \##{id}](#{reservation_url(self, only_path: false)})"
  end
end
