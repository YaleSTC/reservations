FactoryGirl.define do
  factory :cart do
    reserver_id { FactoryGirl.create(:user).id }
    start_date { Date.current }
    due_date { (Date.current+1.day) }
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

      start_date Date.current
      due_date { (Date.current+1.day) + EquipmentModel.find(items.keys.first).category.max_checkout_length + 1.day }

    end
  end
end
