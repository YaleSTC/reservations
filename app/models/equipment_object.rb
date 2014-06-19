class EquipmentObject < ActiveRecord::Base

  include Searchable

  belongs_to :equipment_model
  has_one :category, through: :equipment_model
  has_many :reservations

  validates :name,
            :equipment_model, presence: true

  nilify_blanks only: [:deleted_at]

  attr_accessible :name, :serial, :equipment_model_id, :equipment_model, :deleted_at
  attr_accessible :deactivation_reason

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, where("#{table_name}.deleted_at is null")

  searchable_on(:name, :serial)

  def status
    if self.deleted?
      "Deactivated"
    elsif r = self.current_reservation
      "checked out by #{r.reserver.name} through #{r.due_date.strftime("%b %d")}"
    else
      "available"
    end
  end

  def current_reservation
    self.reservations.each do |r|
      if !r.checked_out.nil? && r.checked_in.nil?
        return r
      end
    end
    return nil
  end

  def available?
    status == "available"
  end

end
