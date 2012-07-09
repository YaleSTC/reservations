class AppConfig < ActiveRecord::Base

  attr_accessible :site_title

  
  validates :site_title, :presence => true
  
end