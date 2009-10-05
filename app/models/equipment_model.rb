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
end
