class Category < ActiveRecord::Base
  has_many :equipment_models
  
  validates :name,                :presence => true, 
                                  :uniqueness => true 
  validates :max_per_user,        :numericality => { :only_integer => true }, 
                                  :length => { :minimum => 1 }, 
                                  :allow_nil => true
  validates :max_checkout_length, :numericality => { :only_integer => true }, 
                                  :length => { :minimum => 1 },  
                                  :allow_nil => true
  
  
  attr_accessible :name, :max_per_user, :max_checkout_length, :deleted_at
  
  nilify_blanks :only => [:deleted_at]  

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
    (self.find(:all, :order => 'name ASC') - [self.find_by_name("Accessories")]).collect{|item| "<option value='#{item.id}'>#{item.name.singularize}</option>"}.join.html_safe
  end
end
