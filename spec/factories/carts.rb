FactoryGirl.define do
  factory :cart do
    reserver_id { FactoryGirl.create(:user).id }
    start_date { Date.current }
    due_date { Date.tomorrow }
    items {}

    factory :cart_with_items do
      items do
        e = FactoryGirl.create(:equipment_model)
        FactoryGirl.create(:equipment_object, equipment_model: e)
        { e.id => 1 }
      end
    end

    factory :invalid_cart do
      items do
        e = FactoryGirl.create(:equipment_model)
        FactoryGirl.create(:equipment_object, equipment_model: e)
        { e.id => 1 }
      end

      start_date Date.current
      due_date do
        Date.tomorrow\
        + EquipmentModel.find(items.keys.first).category.max_checkout_length\
        + 1.day
      end
    end
  end
end
