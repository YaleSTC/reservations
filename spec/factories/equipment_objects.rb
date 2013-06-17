# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :equipment_object do
  	sequence(:name) {|n| "EquipmentObject#{n}"}
  	equipment_model
  end
end