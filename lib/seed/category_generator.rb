# frozen_string_literal: true
module CategoryGenerator
  def self.generate
    Category.create! do |c|
      category_name = FFaker::Product.brand
      category_names = Category.all.to_a.map!(&:name)

      # Verify uniqueness of category name
      while category_names.include?(category_name)
        category_name = FFaker::Product.brand
      end

      c.name = category_name

      c.max_per_user = rand(1..40)
      c.max_checkout_length = rand(1..40)
      c.sort_order = rand(100)
      c.max_renewal_times = rand(0..40)
      c.max_renewal_length = rand(0..40)
      c.renewal_days_before_due = rand(0..9001)
    end
  end
end
