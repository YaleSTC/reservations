# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :category do
  	id 1
    name "Camera"
    max_per_user 1
    max_checkout_length 5
    max_renewal_times 1
    max_renewal_length 5
    renewal_days_before_due 1
  end

  factory :microphone, class: Category do
  	id 2
  	name "Microphone"
  	max_per_user 1
  	max_checkout_length 5
  	max_renewal_times 1
  	max_renewal_length 5
  	renewal_days_before_due 1
  end
end
