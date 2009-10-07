class Document < ActiveRecord::Base
  belongs_to :equipment_model
  has_attached_file :data, :styles => { :small => "150x150>" }, :whiny => false
  
  named_scope :images, :conditions => ["data_content_type LIKE ?", "image%"]
  named_scope :not_images, :conditions => ["data_content_type NOT LIKE ?", "image%"]
  
  before_save :change_name
  validates_presence_of :name
  
  attr_accessible :name, :data, :data_file_name, :data_content_type, :data_file_size
  
  def change_name
    self.name = "untitled" if (self.name == "Enter name of image" or self.name == "Enter name of document")
  end
end
