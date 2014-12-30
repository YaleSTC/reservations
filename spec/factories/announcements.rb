# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :announcement do
    message 'MyText'
    starts_at Date.current
    ends_at Date.tomorrow
  end
end
