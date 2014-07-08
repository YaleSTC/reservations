FactoryGirl.define do
  factory :cart do
    reserver_id { FactoryGirl.create(:user).id }
    start_date { Date.today }
    due_date { Date.tomorrow }
    items {}

    factory :cart_with_items do
      items { {FactoryGirl.create(:equipment_model).id => 1} }
    end

    factory :invalid_cart do
      items { { FactoryGirl.create(:equipment_model).id => 1} }
      start_date Date.today
      due_date { Date.today + (FactoryGirl.attributes_for(:equipment_model)[:max_per_user]+1).day }

    end
  end
end
