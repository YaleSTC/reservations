# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :equipment_object do
    id 1
    name "First"
    serial "FGH4567"
    equipment_model factory: :equipment_model
  end

  factory :deactivated, class: EquipmentObject do
    id 2
    name "Second"
    serial "FGH4568"
    equipment_model factory: :another_equipment_model
    deleted_at "2013-01-01 00:00:00"
  end
end