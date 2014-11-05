class EquipmentObject < ActiveRecord::Base

  include Searchable
  include Rails.application.routes.url_helpers

  has_paper_trail

  belongs_to :equipment_model
  has_one :category, through: :equipment_model
  has_many :reservations

  validates :name,
            :equipment_model, presence: true

  nilify_blanks only: [:deleted_at]

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, lambda { where("#{table_name}.deleted_at is null") }

  searchable_on(:name, :serial)

  def status
    if self.deleted? and self.deactivation_reason
      "Deactivated (#{self.deactivation_reason})"
    elsif self.deleted?
      "Deactivated"
    elsif r = self.current_reservation
      "checked out by #{r.reserver.name} through #{r.due_date.strftime("%b %d")}"
    else
      "available"
    end
  end

  def current_reservation
    return self.reservations.checked_out.first
  end

  def available?
    status == "available"
  end

  def self.for_eq_model(model_id,source_objects)
    # count the number of equipment objects for a given
    # model out of an array of source objects
    # 0 queries

    count = 0
    source_objects.each do |o|
      count += 1 if o.equipment_model_id == model_id
    end
    count
  end

  def make_reservation_notes(procedure_verb, reservation, handler, new_notes)
    new_str = "#### [#{procedure_verb.capitalize}](#{reservation_path(reservation.id)}) by #{handler.md_link} for #{reservation.reserver.md_link} on #{Time.current.to_s(:long)}\n"
    unless new_notes.empty?
      new_str += "##### Notes:\n#{new_notes}\n\n"
    else
      new_str += "\n"
    end
    new_str += self.notes
    self.update_attributes(notes: new_str)
  end

  def make_switch_notes(old_res, new_res, handler)
    # set text depending on whether or not reservations are passed in
    old_res_msg = old_res ? old_res.md_link : 'available'
    new_res_msg = new_res ? new_res.md_link : 'available'
    self.update_attributes(notes: "#### Switched by #{handler.md_link} from #{old_res_msg} to #{new_res_msg} on #{Time.current.to_s(:long)}\n\n" + self.notes)
  end

end
