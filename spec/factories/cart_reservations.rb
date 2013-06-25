# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cart_reservation do
    start_date { Date.today }
    due_date { Date.tomorrow }
    reserver
    equipment_model
  end
end