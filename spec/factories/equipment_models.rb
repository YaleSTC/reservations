# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :equipment_model do
    id 1
    name "Model"
    description "This is a model"
    late_fee "37.50"
    replacement_fee "20"
    max_per_user 10
    category factory: :category
    max_renewal_times 10
    max_renewal_length 10
    renewal_days_before_due 10
  end

  factory :another_equipment_model, class: EquipmentModel do
    id 2
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

  factory :accessory, parent: :equipment_model do
    id 3
    name "Accessory"
    description "Accessory to a model with an accessory."
    category factory: :microphone
  end

  factory :model_with_accessory, parent: :equipment_model do
    id 4
    name "Model with Accessory"
    description "An equipment model with another equipment model as an accessory."
    after(:build) do |model_with_accessory|
      FactoryGirl.create(:accessory, associated_equipment_models: [model_with_accessory])
    end
  end
end
