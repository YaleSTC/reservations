# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :equipment_object do
  	id 1
    name "Number FGH4567"
    serial "FGH4567"
    equipment_model 1 #need to build the equipment_model factory and pass in one of those objects here.
    equipment_model_id 1
    deleted_at ""
  end
end
