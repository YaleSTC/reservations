# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :category do
    sequence(:name) {|n| "Category#{n}"}
    max_per_user { r.rand(1..40) }
    max_checkout_length { r.rand(5..40) }
    sort_order { r.rand(100) }
    max_renewal_times { r.rand(0..40) }
    max_renewal_length { r.rand(0..40) }
    renewal_days_before_due { r.rand(0..9001) }
  end
end