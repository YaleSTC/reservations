class EquipmentModel < ActiveRecord::Base
  belongs_to :category
  has_many :equipment_objects
  
  attr_accessible :name, :category_id, :description, :late_fee, :replacement_fee, :max_per_user
  
  def self.select_options
    self.find(:all, :order => 'name ASC').collect{|item| [item.name, item.id]}
  end
end
