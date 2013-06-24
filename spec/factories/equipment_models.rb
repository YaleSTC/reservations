# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :equipment_model do
    name "MyString"
    description "MyString"
    late_fee "37.50"
    replacement_fee "20"
    max_per_user 1
    category factory: :category
    max_renewal_times 1
    max_renewal_length 1
    renewal_days_before_due 1
  end

  factory :another_equipment_model, class: EquipmentModel do
    name "Another Model"
    description "Not the same as the first model"
    late_fee "37.50"
    replacement_fee "20"
    max_per_user 1
    category factory: :microphone
    max_renewal_times 1
    max_renewal_length 1
    renewal_days_before_due 1
  end
end
