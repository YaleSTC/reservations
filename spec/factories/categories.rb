# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :category do
    name
    sort_order
    max_per_user 5
    max_checkout_length 10
  end
end
