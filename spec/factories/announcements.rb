# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :announcement do
    message "MyText"
    starts_at "2013-06-16 23:08:54"
    ends_at "2013-06-16 23:08:54"
  end
end
