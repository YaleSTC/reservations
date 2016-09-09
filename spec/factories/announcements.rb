# frozen_string_literal: true
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :announcement do
    message 'MyText'
    starts_at Time.zone.today
    ends_at Time.zone.today + 1.day
  end
end
