class EquipmentModel < ActiveRecord::Base
  belongs_to :category
  has_many :equipment_objects
  has_many :documents
  has_and_belongs_to_many :reservations
  
  attr_accessible :name, :category_id, :description, :late_fee, :replacement_fee, :max_per_user, :document_attributes
  
  def self.select_options
    self.find(:all, :order => 'name ASC').collect{|item| [item.name, item.id]}
  end
  
  def document_attributes=(document_attributes)
    document_attributes.each do |attributes|
      documents.build(attributes)
    end
  end
end
