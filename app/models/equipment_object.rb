class EquipmentObject < ActiveRecord::Base

  include Searchable

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
    self.reservations.each do |r|
      return r if r.checked_out && r.checked_in.nil?
    end
    return nil
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

end
