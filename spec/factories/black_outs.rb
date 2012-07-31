# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :black_out do
    equipment_model 1
    start_date "2012-06-27 08:45:56"
    end_date "2012-06-27 08:45:56"
    notice "MyText"
    created_by 1
    type 1
  end
end
