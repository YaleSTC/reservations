class Category < ActiveRecord::Base
  include Searchable
  searchable_on(:name)

  has_many :equipment_models, dependent: :destroy

  validates :name,                presence: true,
                                  uniqueness: true

  validates :max_per_user,
            :max_checkout_length,
            :max_renewal_length,
            :max_renewal_times,
            :renewal_days_before_due,
            :sort_order,
                                  numericality: {
                                    allow_nil: true,
                                    integer_only: true,
                                    greater_than_or_equal_to: 0 }

  nilify_blanks only: [:deleted_at]

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, lambda { where("#{table_name}.deleted_at is null") }

  def maximum_per_user
    max_per_user || Float::INFINITY
  end

  def maximum_renewal_length
    max_renewal_length || 0
  end

  def maximum_renewal_times
    max_renewal_times || Float::INFINITY
  end

  def maximum_renewal_days_before_due
    renewal_days_before_due || Float::INFINITY
  end

  def maximum_checkout_length
    max_checkout_length || Float::INFINITY
  end

end
