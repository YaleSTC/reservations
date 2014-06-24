# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :blackout do
    notice "MyText"
    equipment_model_id 1
    blackout_type 'hard'
    start_date Date.today
    end_date Date.tomorrow
  end
  factory :blackout_in_set do
    set_id 1
  end
end
