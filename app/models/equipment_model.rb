# frozen_string_literal: true

# rubocop:disable ClassLength
class EquipmentModel < ApplicationRecord
  include ApplicationHelper
  include Linkable
  include Searchable

  searchable_on(:name, :description)

  nilify_blanks only: [:deleted_at]

  # table_name is needed to resolve ambiguity for certain queries with
  # 'includes'
  scope :active, ->() { where("#{table_name}.deleted_at is null") }

  ##################
  ## Associations ##
  ##################

  belongs_to :category
  has_and_belongs_to_many :requirements
  has_many :equipment_items, dependent: :destroy
  has_many :reservations
  has_many :checkin_procedures, dependent: :destroy
  accepts_nested_attributes_for :checkin_procedures, \
                                reject_if: :all_blank, allow_destroy: true
  has_many :checkout_procedures, dependent: :destroy
  accepts_nested_attributes_for :checkout_procedures, \
                                reject_if: :all_blank, allow_destroy: true

  # Equipment Models are associated with other equipment models to help us
  # recommend items that go together. Ex: a camera, camera lens, and tripod
  has_and_belongs_to_many :associated_equipment_models,
                          class_name: 'EquipmentModel',
                          association_foreign_key:
                            'associated_equipment_model_id',
                          join_table:
                            'equipment_models_associated_equipment_models'

  ##################
  ## Validations  ##
  ##################

  validates :name,
            :description,
            :category,     presence: true
  validates :name,         uniqueness: true
  validates :late_fee,     :replacement_fee,
            numericality: { greater_than_or_equal_to: 0 }
  validates :max_per_user,
            :max_checkout_length, numericality: { allow_nil: true,
                                                  only_integer: true,
                                                  greater_than_or_equal_to: 1 }
  validates :max_renewal_length,
            :max_renewal_times,
            :renewal_days_before_due,
            numericality: { allow_nil: true, only_integer: true,
                            greater_than_or_equal_to: 0 }

  validate :not_associated_with_self

  def not_associated_with_self
    return if associated_equipment_models.where(id: id).blank?
    errors.add(:associated_equipment_models,
               'You cannot associate a model with itself. Please deselect '\
                 + name)
  end

  #################
  ## Paperclip   ##
  #################

  has_attached_file :photo, # generates profile picture
                    styles: {
                      large: { geometry: '500x500', format: 'png' },
                      medium: { geometry: '250x250', format: 'png' },
                      small: { geometry: '150x150', format: 'png' },
                      thumbnail: { geometry: '260x180', format: 'png' }
                    },
                    convert_options: {
                      large:
                        '-background none -gravity center -extent 500x500',
                      medium:
                        '-background none -gravity center -extent 250x250',
                      small:
                        '-background none -gravity center -extent 150x150',
                      thumbnail:
                        '-background none -gravity center -extent 260x180'
                    },
                    url: paperclip_url,
                    path: ':rails_root/public/attachments/equipment_models/'\
                      ':attachment/:id/:style/:basename.:extension',
                    default_url: '/fat_cat.jpeg',
                    preserve_files: true

  has_attached_file :documentation, # generates document
                    content_type: 'application/pdf',
                    url: paperclip_url,
                    path: ':rails_root/public/attachments/equipment_models/'\
                      ':attachment/:id/:style/:basename.:extension',
                    preserve_files: true

  validates_attachment_content_type :photo,
                                    content_type: ['image/jpg', 'image/png',
                                                   'image/jpeg'],
                                    message: 'must be jpeg, jpg, or png.'
  validates_attachment_size :photo,
                            less_than: 1.megabytes,
                            message: 'must be less than 1 MB in size'
  validates_attachment_content_type :documentation,
                                    content_type: ['application/pdf'],
                                    message: 'must be pdf'

  validates_attachment_size :documentation,
                            less_than: 5.megabytes,
                            message: 'must be less than 5 MB in size'

  Paperclip.interpolates :normalized_photo_name do |attachment, _style|
    attachment.instance.normalized_photo_name
  end

  def normalized_photo_name
    "#{id}-#{photo_file_name.gsub(/[^a-zA-Z0-9_\.]/, '_')}"
  end

  ######################
  ## Instance Methods ##
  ######################

  # inherits from category if not defined

  def maximum_checkout_length
    max_checkout_length || category.maximum_checkout_length
  end

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

  def active_reservations
    if AppConfig.check :requests_affect_availability
      reservations.not_overdue.active_or_requested
    else
      reservations.not_overdue.active
    end
  end

  def num_busy(start_date, due_date, source)
    # get the number busy (not able to be reserved) in the source reservations
    # uses 0 queries
    max = Reservation.number_for_date_range(source, start_date..due_date,
                                            equipment_model_id: id,
                                            overdue: false).max
    max ||= 0
    max + overdue_count
  end

  def num_available(start_date, due_date, source = nil)
    # get the number available in the given date range
    # 1 queries if source given; 2 otherwise
    #
    # source is an array of reservations that can replace a database call
    #   for database query optimization purposes
    source ||= active_reservations.overlaps_with_date_range(start_date,
                                                            due_date)
    equipment_items.active.count - num_busy(start_date, due_date, source)
  end

  def num_available_on(date)
    # get the total number of items of this kind then subtract the total
    # quantity currently reserved, checked-out, and overdue
    busy = active_reservations.overlaps_with_date_range(date, date).count
    equipment_items.active.count - busy - overdue_count
  end

  # figure out the qualitative status of this model's items
  def availability(date)
    num = num_available_on(date)
    total = equipment_items.active.count
    if num <= 0 then 'none'
    elsif num == total then 'all'
    else 'some'
    end
  end

  # Returns true if the reserver is ineligible to checkout the model.
  def model_restricted?(reserver_id)
    return false if reserver_id.nil?
    reserver = User.find(reserver_id)
    !(requirements - reserver.requirements).empty?
  end
end
