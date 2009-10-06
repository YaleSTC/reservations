class EquipmentModel < ActiveRecord::Base
  belongs_to :category
  has_many :equipment_objects
  has_many :documents
  #has_and_belongs_to_many :reservations
  has_many :equipment_models_reservations
  has_many :reservations, :through => :equipment_models_reservations
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :description
  validates_numericality_of :late_fee
  validates_numericality_of :replacement_fee
  validates_numericality_of :max_per_user, :allow_nil => true
  
  attr_accessible :name, :category_id, :description, :late_fee, :replacement_fee, :max_per_user, :document_attributes
  
  def maximum_per_user
    max_per_user || "unrestricted"
  end
  
  def self.select_options
    self.find(:all, :order => 'name ASC').collect{|item| [item.name, item.id]}
  end
  
  def document_attributes=(document_attributes)
    document_attributes.each do |attributes|
      documents.build(attributes)
    end
  end
  
  def available?(date_range)
    overall_count = self.equipment_objects.size
    date_range.each do |date|
      available_on_date = available_count(date)
      overall_count = available_on_date if available_on_date < overall_count
      return false if overall_count == 0
    end
    overall_count
  end
  
  def available_count(date=Date.today)
    # get the total number of objects of this kind
    # then subtract the total quantity currently checked out, reserved, or overdue
    # TODO: the system does not account for early checkouts.
        
    overdue_reservations = Reservation.find(:all, :conditions => ["checked_out != NULL and checked_in = NULL and due_date < ?", date.to_time.utc])
    overdue_count = 0
    overdue_reservations.each do |overdue_reservation|
      overdue_reservation.equipment_models_reservations.each do |equipment_models_reservation|
        overdue_count += equipment_models_reservation.quantity if equipment_models_reservation.equipment_model == self
      end
    end
    
    reserved_count = EquipmentModelsReservation.sum(:quantity, :include => :reservation, :conditions => ["equipment_model_id = ? AND reservations.start_date <= ? AND reservations.due_date >= ? AND reservations.checked_in IS NULL", self.id, date.to_time.utc, date.to_time.utc])
    
    self.equipment_objects.count - reserved_count - overdue_count
  end
  
  def available_object_select_options
    self.equipment_objects.select{|e| e.available?}.sort_by(&:name).collect{|item| "<option value=#{item.id}>#{item.name}</option>"}
  end
end
