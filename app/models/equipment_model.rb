class EquipmentModel < ActiveRecord::Base
  ## Associations ##

  belongs_to :category
  has_many :equipment_objects
  has_many :documents
  # has_and_belongs_to_many :reservations
  # has_many :equipment_models_reservations
  has_many :reservations
  has_and_belongs_to_many :associated_equipment_models,
                          :class_name => "EquipmentModel",
                          :association_foreign_key => "associated_equipment_model_id",
                          :join_table => "equipment_models_associated_equipment_models"
  has_many :checkin_procedures, :dependent => :destroy
  accepts_nested_attributes_for :checkin_procedures, :reject_if => :all_blank, :allow_destroy => true
  has_many :checkout_procedures, :dependent => :destroy
  accepts_nested_attributes_for :checkout_procedures, :reject_if => :all_blank, :allow_destroy => true

  # Equipment Models are associated with other equipment models to help us recommend items that go together.
  # Ex: a camera, camera lens, and tripod
  has_and_belongs_to_many :associated_equipment_models,
    :class_name => "EquipmentModel",
    :association_foreign_key => "associated_equipment_model_id",
    :join_table => "equipment_models_associated_equipment_models"

  #Checkin/out procedures are stored as an independent object each.
  #These nested models are displayed in the equipment_model/_form.html.erb by the cocoon gem
  has_many :checkin_procedures, :dependent => :destroy
  accepts_nested_attributes_for :checkin_procedures, :reject_if => :all_blank, :allow_destroy => true
  has_many :checkout_procedures, :dependent => :destroy
  accepts_nested_attributes_for :checkout_procedures, :reject_if => :all_blank, :allow_destroy => true

  #This old style of associating with accessories we've removed from the program.
  #If you're reading this line, it's probably safe to remove these lines by now.
  ##associates with itself for accessories/recommended related models
  ##has_many :accessories_equipment_models, :foreign_key => :equipment_model_id
  ##has_many :accessories, :through => :accessories_equipment_models



  ## Validations ##

  validates :name, 
            :description,
            :category,     :presence => true
  validates :name,         :uniqueness => true
  validates :late_fee,     :replacement_fee, 
                           :numericality => { :greater_than_or_equal_to => 0 }
  validates :max_per_user, :numericality => { :allow_nil => true, :integer_only => true, :greater_than_or_equal_to => 1 }
  validates :max_renewal_length,       :numericality => { :allow_nil => false, :integer_only => true, :greater_than_or_equal_to => 0 }
  validates :max_renewal_times,
            :renewal_days_before_due,  :numericality => { :allow_nil => true, :integer_only => true, :greater_than_or_equal_to => 0 }

  nilify_blanks :only => [:deleted_at]
  
  include ApplicationHelper
  
  attr_accessible :name, :category_id, :description, :late_fee, :replacement_fee, 
                  :max_per_user, :document_attributes, :accessory_ids, :deleted_at, 
                  :checkout_procedures_attributes, :checkin_procedures_attributes, :photo, 
                  :documentation, :max_renewal_times, :max_renewal_length, :renewal_days_before_due

  #Code necessary for Paperclip and image/pdf uploading
  has_attached_file :photo, #generates profile picture 
      :styles => { :large => "500x500>", :medium => "250x250>", :small => "150x150>", :thumbnail => "100x100#"},
      :url  => "/equipment_models/:attachment/:id/:style/:basename.:extension",
      :path => ":rails_root/public/equipment_models/:attachment/:id/:style/:basename.:extension",
      :default_url => "/fat_cat.jpeg"

  has_attached_file :documentation, #generates document
                    :content_type => 'application/pdf'
      
  # validates_attachment_content_type :photo, 
  #                                     :content_type => ["image/jpg", "image/png", "image/jpeg"], 
  #                                     :message => "must be jpeg, jpg, or png."
  #   validates_attachment_size         :photo, 
  #                                     :less_than => 500.kilobytes,
  #                                     :message => "must be less than 500 kb"
  
  #validates_attachment :documentation, :content_type => { :content_type => "appplication/pdf" }
  
  Paperclip.interpolates :normalized_photo_name do |attachment, style|
    attachment.instance.normalized_photo_name
  end
  
  def normalized_photo_name
    "#{self.id}-#{self.photo_file_name.gsub( /[^a-zA-Z0-9_\.]/, '_')}" 
  end
  #end of Paperclip code. 


  ## Functions ##


  #inherits from category if not defined
  def maximum_per_user
    max_per_user || category.maximum_per_user
  end
  
  def maximum_renewal_length
    max_renewal_length || category.maximum_renewal_length
  end
  
  def maximum_renewal_times
    max_renewal_times || category.maximum_renewal_times
  end
  
  def maximum_renewal_days_before_due
    renewal_days_before_due || category.maximum_renewal_days_before_due
  end

  def self.select_options
    self.order('name ASC').collect{|item| [item.name, item.id]}
  end

  def document_attributes=(document_attributes)
    document_attributes.each do |attributes|
      documents.build(attributes)
    end
  end

  def formatted_description
    lines = self.description.split(/^/)

    nice_content = "<p>"
    lines.each do |line|
      if line.include? "<table>" or line.include? "<td>"
        nice_content += line
      else
        nice_content += line + "<br />"
      end
    end
    nice_content += "</p>"
  end

  def photos
    self.documents.images
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
  
  def available_count(date)
    # get the total number of objects of this kind
    # then subtract the total quantity currently checked out, reserved, or overdue
    # TODO: the system does not account for early checkouts.

    reserved_count = Reservation.where("checked_in IS NULL and checked_out IS NULL and equipment_model_id = ? and start_date <= ? and due_date >= ?", self.id, date.to_time.utc, date.to_time.utc).size
    overdue_count = Reservation.where("checked_in IS NULL and checked_out IS NOT NULL and equipment_model_id = ? and due_date <= ?", self.id, Date.today.to_time.utc).size

    self.equipment_objects.count - reserved_count - overdue_count
  end

  def available_object_select_options
    self.equipment_objects.select{|e| e.available?}.sort_by(&:name).collect{|item| "<option value=#{item.id}>#{item.name}</option>"}.join.html_safe
  end
  
  def fake_category_id
    self
  end

#  def max_renewal_times # number of times you're allowed to renew an item
#  end
  
#  def max_renewal_length # in days
#    max_renewal_length = 0 if max_renewal_length == NIL # MUST SET AN INTEGER VALUE
#  end
  
#  def renewal_days_before_due # in days
#  end

end
