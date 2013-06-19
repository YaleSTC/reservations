# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :name do |n|
    "EquipmentModel#{n}"
  end

  factory :equipment_model do
    name { generate(:name)}
    description "This is a description of an Equipment Model"
    late_fee 0
    replacement_fee 0
    active true
    category

    factory :equipment_model_with_object do
      after(:create) do |model|
        FactoryGirl.create(:equipment_object, equipment_model: model)
      end
    end
  end
end