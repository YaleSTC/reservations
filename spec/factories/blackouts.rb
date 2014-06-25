# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :blackout do
    notice "MyText"
    equipment_model_id 0
    blackout_type 'hard'
    start_date Date.today
    end_date Date.tomorrow
  end

end
