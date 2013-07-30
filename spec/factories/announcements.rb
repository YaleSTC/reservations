# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :announcement do
    messag "MyText"
    starts_at "2013-07-30 01:40:23"
    ends_at "2013-07-30 01:40:23"
  end
end
