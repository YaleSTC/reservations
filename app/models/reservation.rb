class Reservation < ActiveRecord::Base
  include ReservationValidations
  include ReservationScopes
  include Routing

  belongs_to :equipment_model
  belongs_to :equipment_object
  belongs_to :reserver, class_name: 'User'
  belongs_to :checkout_handler, class_name: 'User'
  belongs_to :checkin_handler, class_name: 'User'

  validates :equipment_model, :start_date, :due_date, presence: true
  validates_each :reserver do |record, attr, value|
    record.errors.add(attr, 'cannot be a guest') if value.role == 'guest'
  end
  validate :start_date_before_due_date
  validate :matched_object_and_model
  validate :not_in_past, :available, on: :create

  nilify_blanks only: [:notes]

  ## Class methods ##

  def self.unique_equipment_objects?(reservations)
    object_ids = reservations.map(&:equipment_object_id)
    return object_ids == object_ids.uniq
  end

  def self.number_for_model_on_date(date,model_id,source)
    # count the number of reservations that overlaps a date within
    # a given array of source reservations and that matches
    # a specific model id
    #
    # this code is used largely in validations because it uses 0 queries
    count = 0
    source.each do |r|
      count += 1 if r.start_date.to_date <= date && r.due_date.to_date >= date && r.equipment_model_id == model_id
    end
    count
  end

  def self.number_for_category_on_date(date,category_id,reservations)
    count = 0
    reservations.each do |r|
      count += 1 if r.start_date.to_date <= date && r.due_date.to_date >= date && r.equipment_model.category_id == category_id
    end
    return count
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

  def status
    if checked_out.nil?
      if approval_status == 'auto' or approval_status == 'approved'
        due_date >= Date.current ? "reserved" : "missed"
      elsif approval_status
        approval_status
      else
        "?" # ... is this just in case an admin does something absurd in the database?
      end
    elsif checked_in.nil?
      due_date < Date.current ? "overdue" : "checked out"
    else
      due_date < checked_in.to_date ? "returned overdue" : "returned on time"
    end
  end

  def duration
    due_date.to_date - start_date.to_date + 1
  end

  def late_fee
    self.equipment_model.late_fee.to_f
  end

  def reserver
    User.find(self.reserver_id)
  rescue
    #if user's been deleted, return a dummy user
    User.new( first_name: "Deleted",
              last_name: "User",
              username: "deleted",
              email: "deleted.user@invalid.address",
              nickname: "",
              phone: "555-555-5555",
              affiliation: "Deleted")
  end

  def fake_reserver_id # this is necessary for autocomplete! delete me not!
  end

  ## Instance method helper/misc  ##

  def find_renewal_date
    # determine the max renewal length for a given reservation
    # O(n) queries
    renew_extension = self.dup
    renew_extension.start_date = self.due_date + 1.day
    orig_due_date = self.due_date
    eq_model = self.equipment_model

    eq_model.maximum_renewal_length.downto(1).each do |r|
      renew_extension.due_date = orig_due_date + r.days
      if renew_extension.validate_renew.empty?
        return renew_extension.due_date
      end
    end
    return self.due_date
  end

  def is_eligible_for_renew?
    # determines if a reservation is eligible for renewal, based on how many days before the due
    # date it is and the max number of times one is allowed to renew
    #
    self.times_renewed ||= 0

    # you can't renew a checked in reservation, or one without an equipment model
    return false if self.checked_in || self.equipment_object.nil?

    max_renewal_times = self.equipment_model.maximum_renewal_times

    max_renewal_days = self.equipment_model.maximum_renewal_days_before_due
    return ((self.due_date.to_date - Date.current).to_i < max_renewal_days) &&
      (self.times_renewed < max_renewal_times) &&
      self.equipment_model.maximum_renewal_length > 0
  end

  def to_cart
    temp_cart = Cart.new
    temp_cart.start_date = self.start_date
    temp_cart.due_date = self.due_date
    temp_cart.reserver_id = self.reserver_id
    temp_cart.items = { self.equipment_model_id => 1 }
    temp_cart
  end


  ## Instance methods that alter the status of a reservation ##


  def renew(user)
    # renew the reservation and return error messages if unsuccessful
    return "Reservation not eligible for renewal" unless self.is_eligible_for_renew?
    self.due_date = self.find_renewal_date
    self.notes += "\n\n### Renewed on #{Time.current.to_s(:long)} by #{user.md_link}\n\nThe new due date is #{self.due_date.to_date.to_s(:long)}."
    return "Unable to update reservation dates!" unless self.save
    return nil
  end

  def checkin(checkin_handler, procedures, new_notes)
    # Checks in a reservation with the given checkin handler
    # and hash of checkin procedures and any manually entered
    # notes from the checkin
    #
    # Returns the unsaved, checked in reservation

    self.checkin_handler = checkin_handler
    self.checked_in = Time.current

    # gather all the procedure texts that were not
    # checked, ie not included in the procedures hash
    incomplete_procedures = []
    procedures = [procedures].flatten # in case of nil procedures
    self.equipment_model.checkin_procedures.each do |checkin_procedure|
      if procedures.exclude?(checkin_procedure.id.to_s)
        incomplete_procedures << checkin_procedure.step
      end
    end
    self.make_notes("Checked in", new_notes, incomplete_procedures, checkin_handler)
    # update equipment object notes
    self.equipment_object.make_reservation_notes("checked in", self, checkin_handler, new_notes, Time.current)

    if self.checked_in.to_date > self.due_date.to_date
      # equipment was overdue, send an email confirmati
        AdminMailer.overdue_checked_in_fine_admin(self).deliver
        UserMailer.overdue_checked_in_fine(self).deliver
    end

    self
  end

  def archive(archiver, note)
    # set the reservation as checked in if it has been checked out
    # used for emergency situations or when equipment is deactivated
    # to preserve database sanity (eg, equipment object is deactivated while
    # that reseration is checked out)
    # returns self
    if self.checked_in.nil?
      self.checked_in = Time.current
      self.checked_out = Time.current if self.checked_out.nil?
      # archive equipment object if checked out
      self.equipment_object.make_reservation_notes("archived", self, archiver, "#{note}", Time.current) if self.equipment_object
      self.notes = self.notes.to_s + "\n\n### Archived on #{Time.current.to_s(:long)} by #{archiver.md_link}\n\n\n#### " +
        "Reason:\n#{note}\n\n#### The checkin and checkout dates may reflect the archive date because the reservation was " +
        "for a nonexistent piece of equipment or otherwise problematic."
    end
    self
  end

  def checkout(eq_object, checkout_handler, procedures, new_notes)
    # checks out a reservation with the given eq object, checkout handler
    # and a hash of checkout procedures and any manually entered
    # notes from the checkout.
    #
    # Returns the unsaved, checked out reservation

    self.checkout_handler = checkout_handler
    self.checked_out = Time.current
    self.equipment_object_id = eq_object

    incomplete_procedures = []
    procedures = [procedures].flatten
    self.equipment_model.checkout_procedures.each do |checkout_procedure|
      if procedures.exclude?(checkout_procedure.id.to_s)
        incomplete_procedures << checkout_procedure.step
      end
    end
    self.make_notes("Checked out", new_notes, incomplete_procedures, checkout_handler)
    # update equipment object notes
    self.equipment_object.make_reservation_notes("checked out", self, checkout_handler, new_notes, Time.current)
    self
  end

  def update(current_user, new_params, new_notes)
    # updates a reservation and records changes in the notes
    #
    # takes the current user, the new params from the controller that have
    # been updated w/ a new equipment object, and the new notes (if any)

    self.assign_attributes(new_params)
    changes = self.changes
    new_notes = '' unless new_notes
    if new_notes.empty? && changes.empty?
      self
      return
    else
      # write notes header
      header = "### Edited on #{Time.current.to_s(:long)} by #{current_user.md_link}\n"
      self.notes = self.notes ? self.notes + "\n" + header : header

      # add notes if they exist
      unless new_notes.empty?
        self.notes += "\n\n#### Notes:\n#{new_notes}"
      end

      # record changes
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
            old_val = diff[0].to_date.to_s(:long)
            new_val = diff[1].to_date.to_s(:long)
          when 'due_date'
            name = 'Due Date'
            old_val = diff[0].to_date.to_s(:long)
            new_val = diff[1].to_date.to_s(:long)
          when 'equipment_object_id'
            name = 'Item'
            old_val = diff[0] ? EquipmentObject.find(diff[0]).md_link : 'nil'
            new_val = diff[1] ? EquipmentObject.find(diff[1]).md_link : 'nil'
          end
          self.notes += "\n#{name} changed from " + old_val + " to " + new_val + "."
        end
      end

      self.notes = self.notes.strip
      self
    end
  end

  def make_notes(procedure_verb, new_notes, incomplete_procedures, current_user)
    # handles the reservation notes from the new notes
    #
    # takes the new notes and a string, 'checked in' or 'checked out' as the
    # procedure_kind

    # write notes header
    header = "### #{procedure_verb} on #{Time.current.to_s(:long)} by #{current_user.md_link}\n"
    self.notes = self.notes ? self.notes + "\n" + header : header

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
    unless new_notes.empty?
      self.notes += "\n\n#### Notes:\n#{new_notes}"
    end

    # record note procedure status
    if incomplete_procedures.empty?
      self.notes += "\n\nAll procedures were performed!"
    else
      self.notes += "\n\n#### The following procedures were not performed:\n"
      self.notes += markdown_listify(incomplete_procedures)
    end
    self.notes = self.notes.strip

  end

  # returns a string where each item is begun with a '*'
  def markdown_listify(items)
    return '* ' + items.join("\n* ")
  end

  def md_link
    "[res. \##{self.id.to_s}](#{reservation_url(self, only_path: false)})"
  end

end
