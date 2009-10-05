class Document < ActiveRecord::Base
  belongs_to :equipment_model
  has_attached_file :data
  
  validates_presence_of :name
  
  attr_accessible :name, :data, :data_file_name, :data_content_type, :data_file_size
end
