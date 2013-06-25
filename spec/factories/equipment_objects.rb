# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  sequence :name do |n|
    "Name#{n}"
  end

  sequence :serial do |n|
    "FLKJDSF#{n}"
  end

  factory :equipment_object do
    name
    serial
    equipment_model factory: :equipment_model

    factory :deactivated do
      deleted_at "2013-01-01 00:00:00"
    end
  end
end