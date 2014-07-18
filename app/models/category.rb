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

  #validate :renewal_not_longer_than_checkout

  attr_accessible :name, :max_per_user,
                  :max_checkout_length, :deleted_at,
                  :max_renewal_times, :max_renewal_length,
                  :renewal_days_before_due, :sort_order

  nilify_blanks only: [:deleted_at]

  # table_name is needed to resolve ambiguity for certain queries with 'includes'
  scope :active, where("#{table_name}.deleted_at is null")

  #def renewal_not_longer_than_checkout
   # return if max_checkout_length.nil?
   # if maximum_renewal_length > max_checkout_length
   #   errors.add(:max_renewal_length, "You cannot have a renewal period longer than the maximum checkout length")
   # end
  #end


  def maximum_per_user
    max_per_user || "unrestricted"
  end

  def maximum_renewal_length
    max_renewal_length || 0
  end

  def maximum_renewal_times
    max_renewal_times || "unrestricted"
  end

  def maximum_renewal_days_before_due
    renewal_days_before_due || "unrestricted"
  end

  def maximum_checkout_length
    max_checkout_length || "unrestricted"
    #self.max_checkout_length ? ("#{max_checkout_length} days") : "unrestricted"
  end

end
