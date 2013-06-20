# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :black_out do
    start_date "2013-03-05"
    end_date "2013-03-22"
    notice "MyText"
    equipment_model_id 1
    black_out_type "hard"
  end
end
