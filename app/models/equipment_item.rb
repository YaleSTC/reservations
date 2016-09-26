# frozen_string_literal: true
class EquipmentItem < ActiveRecord::Base
  include Linkable
  include Searchable

  belongs_to :equipment_model, counter_cache: true
  has_one :category, through: :equipment_model
  has_many :reservations

  validates :name,
            :equipment_model, presence: true
  validates :serial, uniqueness: { scope: :equipment_model_id },
                     allow_nil: true, allow_blank: true

  nilify_blanks only: [:deleted_at]

  # table_name is needed to resolve ambiguity for certain queries with
  # 'includes'
  scope :active, ->() { where("#{table_name}.deleted_at is null") }

  searchable_on(:name, :serial)

  def self.for_eq_model(model_id, source_objects)
    # count the number of equipment items for a given
    # model out of an array of source objects
    # 0 queries

    count = 0
    source_objects.each do |o|
      count += 1 if o.equipment_model_id == model_id
    end
    count
  end

  def status
    if deleted? && deactivation_reason
      "Deactivated (#{deactivation_reason})"
    elsif deleted?
      'Deactivated'
    elsif r = current_reservation # rubocop:disable AssignmentInCondition
      "checked out by #{r.reserver.name} through "\
        "#{r.due_date.strftime('%b %d')}"
    else
      'available'
    end
  end

  def current_reservation
    reservations.checked_out.first
  end

  def available?
    status == 'available'
  end

  def make_reservation_notes(procedure_verb, reservation, handler, new_notes,
                             time)
    new_str = "#### #{reservation.md_link(procedure_verb.capitalize)} by "\
      "#{handler.md_link} for #{reservation.reserver.md_link} on "\
      "#{time.to_s(:long)}\n"
    new_str += if new_notes.empty?
                 "\n"
               else
                 "##### Notes:\n#{new_notes}\n\n"
               end
    new_str += notes
    update_attributes(notes: new_str)
  end

  def make_switch_notes(old_res, new_res, handler)
    # set text depending on whether or not reservations are passed in
    old_res_msg = old_res ? old_res.md_link : 'available'
    new_res_msg = new_res ? new_res.md_link : 'available'
    update_attributes(notes: "#### Switched by #{handler.md_link} from "\
                      "#{old_res_msg} to #{new_res_msg} on "\
                      "#{Time.zone.now.to_s(:long)}\n\n" + notes)
  end

  def update(current_user, new_params) # rubocop:disable all
    assign_attributes(new_params)
    changes = self.changes
    return self if changes.empty?
    new_notes = "#### Edited at #{Time.zone.now.to_s(:long)} by "\
      "#{current_user.md_link}\n\n"
    new_notes += "\n\n#### Changes:"
    changes.each do |param, diff|
      case param
      when 'name'
        name = 'Name'
        old_val = diff[0].to_s
        new_val = diff[1].to_s
      when 'serial'
        name = 'Serial'
        old_val = diff[0].to_s
        new_val = diff[1].to_s
      when 'equipment_model_id'
        name = 'Equipment Model'
        old_val = diff[0] ? EquipmentModel.find(diff[0]).name : 'nil'
        new_val = diff[1] ? EquipmentModel.find(diff[1]).name : 'nil'
      end
      new_notes += "\n#{name} changed from " + old_val + ' to ' + new_val\
        + '.' if old_val && new_val
    end
    new_notes += "\n\n" + notes
    self.notes = new_notes.strip
    self
  end

  # Deactivates the equipment item using the #destroy method and
  # `permanent_records`, while appropriately updating the equipment item notes.
  #
  # == Parameters:
  # options::
  #   A hash of inputs, required parameters `:user` (any object that responds to
  #   `md_link`) and `:reason`.
  #
  # == Returns:
  # The equipment item, unchanged if missing inputs or deactivated if passed the
  # appropriate options.
  def deactivate(options = {})
    return unless options[:user] && options[:user].md_link && options[:reason]
    # update notes
    new_notes = "#### Deactivated at #{Time.zone.now.to_s(:long)} by "\
      "#{options[:user].md_link}\n#{options[:reason]}\n\n" + notes
    self.notes = new_notes
    self.deactivation_reason = options[:reason]
    save!
    destroy
    self
  end
end
