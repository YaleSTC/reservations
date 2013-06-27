# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :blackout do
    notice "MyText"
    equipment_model_id 1
    blackout_type 'hard'
  end
end
