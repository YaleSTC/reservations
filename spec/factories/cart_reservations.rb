# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cart_reservation do
    start_date { Date.today }
    due_date { Date.tomorrow }
    reserver
    equipment_model
    # after(:build) do |res|
    #   obj = FactoryGirl.create(:equipment_object, :equipment_model => res.equipment_model)
    #   res.equipment_object = obj
    # end
  end
end
