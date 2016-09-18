# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :blackout do
    notice 'MyText'
    blackout_type 'hard'
    start_date Time.zone.today
    end_date { Time.zone.today + 7.days }
  end
end
