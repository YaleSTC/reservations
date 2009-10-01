class Category < ActiveRecord::Base
  has_many :equipment_models
  
  attr_accessible :name, :max_per_user, :max_checkout_length
  
  def self.select_options
    self.find(:all, :order => 'name ASC').collect{|item| [item.name, item.id]}
  end
end
