class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  has_many :reservations
  
  validates_presence_of :name
  
  attr_accessible :name, :serial, :equipment_model_id
  
  def status
    # last_reservation = Reservation.find(self.reservation_ids.last.to_s)
    self.reservations.each do |r|
      if (!r.checked_out.nil?) && (r.status != "returned")
        return "checked out by #{r.reserver.name} through #{r.due_date.strftime("%b %d")}"
      end
    end
    "available"
  end
  
  def available?
    status == "available"
  end
end
