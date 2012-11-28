class EquipmentObject < ActiveRecord::Base
  belongs_to :equipment_model
  has_one :category, :through => :equipment_model
  has_many :reservations

  validates :name, 
            :equipment_model, :presence => true

  nilify_blanks :only => [:deleted_at]
  
  attr_accessible :name, :serial, :equipment_model_id, :deleted_at

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, where("#{table_name}.deleted_at is null")

  def status
    # last_reservation = Reservation.find(self.reservation_ids.last.to_s)
    return "Deactivated" if self.deleted?
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
      active
    else # in all other cases, search using the query text
      results = []
      query.split.each do |q|
        results << active.where("name LIKE :query OR serial LIKE :query", {:query => "%#{q}%"})
      end
      # take the intersection of the results for each word 
      # i.e. choose results matching all terms
      results.inject(:&)
    end
  end
end
