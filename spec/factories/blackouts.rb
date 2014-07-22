# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :blackout do
    notice "MyText"
    blackout_type 'hard'
    start_date Date.today
    end_date (Date.today + 7.day)
  end

end
