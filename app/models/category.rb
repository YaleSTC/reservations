class Category < ActiveRecord::Base
  has_many :equipment_models
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_numericality_of :max_per_user, :allow_nil => true
  validates_numericality_of :max_checkout_length, :allow_nil => true
  
  attr_accessible :name, :max_per_user, :max_checkout_length
  
  def maximum_per_user
    max_per_user || "unrestricted"
  end
  
  def maximum_checkout_length
    self.max_checkout_length ? ("#{max_checkout_length} days") : "unrestricted"
  end
  
  def self.select_options
    self.find(:all, :order => 'name ASC').collect{|item| [item.name, item.id]}
  end
  
  def self.singular_select_options
    (self.find(:all, :order => 'name ASC') - [self.find_by_name("Accessories")]).collect{|item| "<option value='#{item.id}'>#{item.name.singularize}</option"}
  end
end
