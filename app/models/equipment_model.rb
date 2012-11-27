class EquipmentModel < ActiveRecord::Base
  include ApplicationHelper

  nilify_blanks :only => [:deleted_at]

  attr_accessible :name, :category_id, :description, :late_fee, :replacement_fee,
      :max_per_user, :document_attributes, :accessory_ids, :deleted_at,
      :checkout_procedures_attributes, :checkin_procedures_attributes, :photo,
      :documentation, :max_renewal_times, :max_renewal_length, :renewal_days_before_due, 
      :associated_equipment_model_ids, :requirement_ids, :requirements

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, where("#{table_name}.deleted_at is null")

  ##################
  ## Associations ##
  ##################

  belongs_to :category
  has_and_belongs_to_many :requirements
  has_many :equipment_objects
  has_many :documents
  has_many :reservations
  has_many :checkin_procedures, :dependent => :destroy
  accepts_nested_attributes_for :checkin_procedures, \
                                :reject_if => :all_blank, :allow_destroy => true
  has_many :checkout_procedures, :dependent => :destroy
  accepts_nested_attributes_for :checkout_procedures, \
                                :reject_if => :all_blank, :allow_destroy => true

  # Equipment Models are associated with other equipment models to help us recommend items that go together.
  # Ex: a camera, camera lens, and tripod
  has_and_belongs_to_many :associated_equipment_models,
    :class_name => "EquipmentModel",
    :association_foreign_key => "associated_equipment_model_id",
    :join_table => "equipment_models_associated_equipment_models"

  ##################
  ## Validations  ##
  ##################
  
  validates :name,
            :description,
            :category,     :presence => true
  validates :name,         :uniqueness => true
  validates :late_fee,     :replacement_fee,
                           :numericality => { :greater_than_or_equal_to => 0 }
  validates :max_per_user, :numericality => { :allow_nil => true, \
                                              :integer_only => true, \
                                              :greater_than_or_equal_to => 1 }
  validates :max_renewal_length,
            :max_renewal_times,
            :renewal_days_before_due,  :numericality => { :allow_nil => true, :integer_only => true, :greater_than_or_equal_to => 0 }

  validate :not_associated_with_self

  def not_associated_with_self
    unless self.associated_equipment_models.where(:id => self.id).blank?
      errors.add(:associated_equipment_models, "You cannot associate a model with itself. Please deselect " + self.name)
    end
  end
  
  #################
  ## Paperclip   ##
  #################

  has_attached_file :photo, #generates profile picture
      :styles => {
        :large => { :geometry => "500x500", :format => "png" },
        :medium => { :geometry => "250x250", :format => "png" },
        :small => { :geometry => "150x150", :format => "png" },
        :thumbnail => { :geometry => "260x180", :format => "png" } },
      :convert_options => {
        :large => '-background none -gravity center -extent 500x500',
        :medium => '-background none -gravity center -extent 250x250',
        :small => '-background none -gravity center -extent 150x150',
        :thumbnail => '-background none -gravity center -extent 260x180' },
      :url  => "/attachments/equipment_models/:attachment/:id/:style/:basename.:extension",
      :path => ":rails_root/public/attachments/equipment_models/:attachment/:id/:style/:basename.:extension",
      :default_url => "/fat_cat.jpeg",
      :preserve_files => true


  has_attached_file :documentation, #generates document
      :content_type => 'application/pdf',
      :url => "/attachments/equipment_models/:attachment/:id/:style/:basename.:extension",
      :path => ":rails_root/public/attachments/equipment_models/:attachment/:id/:style/:basename.:extension",
      :preserve_files => true

  validates_attachment_content_type :photo,
      :content_type => ["image/jpg", "image/png", "image/jpeg"],
      :message => "must be jpeg, jpg, or png."
  validates_attachment_size         :photo,
      :less_than => 1.megabytes,
      :message => "must be less than 1 MB in size"
  validates_attachment :documentation, :content_type => { :content_type => "application/pdf" }

  Paperclip.interpolates :normalized_photo_name do |attachment, style|
    attachment.instance.normalized_photo_name
  end

  def normalized_photo_name
    "#{self.id}-#{self.photo_file_name.gsub( /[^a-zA-Z0-9_\.]/, '_')}"
  end

  ###################
  ## Class Methods ##
  ###################

  def self.catalog_search(query)
    if query.blank? # if the string is blank, return all
      active
    else # in all other cases, search using the query text
      results = []
      query.split.each do |q|
        results << active.where("name LIKE :query OR description LIKE :query", {:query => "%#{q}%"})
      end
      # take the intersection of the results for each word 
      # i.e. choose results matching all terms
      results.inject(:&)
    end
  end

  #TODO: this appears to be dead code - verify and remove
  def self.select_options
    self.order('name ASC').collect{|item| [item.name, item.id]}
  end

  ######################
  ## Instance Methods ##
  ######################

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

  def document_attributes=(document_attributes)
    document_attributes.each do |attributes|
      documents.build(attributes)
    end
  end

  #TODO: blackout vs validation
  def num_available(start_date, due_date)
    availability = start_date.to_date.upto(due_date.to_date).map do |date|
       available_count(date)
    end
    availability.min > 0 ? availability.min : 0
  end
  
  # Returns true if the reserver is ineligible to checkout the model.
  def model_restricted?(reserver_id)
    reserver = User.find(reserver_id)
    self.requirements.each do |em_req|
      unless reserver.requirements.include?(em_req)
         return true
      end
    end
    return false
  end


  # Returns the number of reserved objects for a particular model, 
  # as long as they have not been checked out
  def number_reserved_on_date(date) 
    Reservation.reserved_on_date(date).not_returned.for_eq_model(self).size
  end

  # Returns the number of overdue objects for a given model, 
  # as long as they have been checked out.
  def number_overdue 
    Reservation.overdue.for_eq_model(self).size
  end


  def available_count(date)
    # get the total number of objects of this kind
    # then subtract the total quantity currently reserved, and overdue
    total = equipment_objects.active.count
    (total - number_reserved_on_date(date)) - number_overdue
  end

  def available_object_select_options
    self.equipment_objects.active.select{|e| e.available?}\
        .sort_by(&:name)\
        .collect{|item| "<option value=#{item.id}>#{item.name}</option>"}\
        .join.html_safe
  end

end
