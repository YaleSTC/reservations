# Read about factories at https://github.com/thoughtbot/factory_girl

# TODO: Cart is stored in session.
FactoryGirl.define do
  factory :cart do
    reserver_id { FactoryGirl.create(:user).id }
    start_date { Date.today }
    due_date { Date.tomorrow }
    items []

    factory :cart_with_items do
      ignore do
        items_count 2
      end
      after(:create) do |cart, evaluator|
        FactoryGirl.create_list(:cart_reservation, evaluator.items_count, cart: cart)
      end
    end
  end
end
