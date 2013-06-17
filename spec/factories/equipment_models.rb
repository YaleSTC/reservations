# Read about factories at https://github.com/thoughtbot/factory_girl

sequence :name do |n|
  "EquipmentModel#{n}"
end

FactoryGirl.define do
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