FactoryGirl.define do
  factory :cart do
    reserver_id { FactoryGirl.create(:user).id }
    start_date { Date.today }
    due_date { Date.tomorrow }
    items {}

    factory :cart_with_items do
      items { e = FactoryGirl.create(:equipment_model)
              FactoryGirl.create(:equipment_object, equipment_model: e)
              { e.id => 1 } }
    end

    factory :invalid_cart do
      items { e = FactoryGirl.create(:equipment_model)
              FactoryGirl.create(:equipment_object, equipment_model: e)
              { e.id => 1 } }

      start_date Date.today
      due_date { Date.today + (FactoryGirl.attributes_for(:equipment_model)[:max_per_user]+1).day }

    end
  end
end
