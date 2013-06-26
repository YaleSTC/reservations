# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :black_out do
    notice "MyText"
    equipment_model_id 1
    black_out_type 'hard'
  end
end
