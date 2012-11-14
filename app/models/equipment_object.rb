class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  has_one :category, :through => :equipment_model
  has_many :reservations

  validates :name, 
            :equipment_model, :presence => true

  nilify_blanks :only => [:deleted_at]
  
  attr_accessible :name, :serial, :equipment_model_id, :deleted_at
  
  default_scope where(:deleted_at => nil)
   
    def self.include_deleted
      self.unscoped
    end


  def status
    # last_reservation = Reservation.find(self.reservation_ids.last.to_s)
    self.reservations.each do |r|
      if !r.checked_out.nil? && r.checked_in.nil?
        return "checked out by #{r.reserver.name} through #{r.due_date.strftime("%b %d")}"
      end
    end
    "available"
  end
  
  def available?
    status == "available"
  end
  
  def self.catalog_search(query)
    if query.blank? # if the string is blank, return all
      find(:all)
    else # in all other cases, search using the query text
      find(:all, :conditions => ['name LIKE :query OR serial LIKE :query', {:query => "%#{query}%"}])
    end
  end

end
