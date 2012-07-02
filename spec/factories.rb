FactoryGirl.define do

  r = Random.new

  factory :user do
    sequence(:login) {|n| "netid#{n}" }
    first_name {Faker::Name.first_name}
    last_name  {Faker::Name.last_name}
    phone "1234567890"
    email {"#{first_name}.#{last_name}@yale.edu"}
    affiliation "YC"
    adminmode false

    factory :admin do
      adminmode true
    end
  end

  factory :category do
    name Faker::Product.brand + " " + r.rand(1..10).to_s
    max_per_user r.rand(1..40)
    max_checkout_length r.rand(1..40)
    sort_order r.rand(100)
    max_renewal_times r.rand(0..40)
    max_renewal_length r.rand(0..40)
    renewal_days_before_due r.rand(0..9001)
  end

  factory :equipment_model do
    name Faker::Product.product + " " + r.rand(100..901).to_s
    description Faker::HipsterIpsum.paragraph(4)
    late_fee r.rand(50.00..1000.00).round(2).to_d
    replacement_fee r.rand(50.00..1000.00).round(2).to_d
    max_per_user r.rand(1..40)
    active true
    max_renewal_times r.rand(0..40)
    max_renewal_length r.rand(0..40)
    renewal_days_before_due r.rand(0..9001)
    category
  end

  factory :equipment_object do
    name Faker::Product.brand + " " + r.rand(1000..9001).to_s
    serial (10000000...99999999)
    active true
    equipment_model
  end
end
