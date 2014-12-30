# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :blackout do
    notice 'MyText'
    blackout_type 'hard'
    start_date Date.current
    end_date (Date.current + 7.day)
  end
end
