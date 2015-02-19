FactoryGirl.define do
  factory :cart do
    reserver_id { FactoryGirl.create(:user).id }
    start_date { Time.zone.today }
    due_date { Time.zone.today + 1.day }
    items {}

    factory :cart_with_items do
      items do
        e = FactoryGirl.create(:equipment_model)
        FactoryGirl.create(:equipment_item, equipment_model: e)
        { e.id => 1 }
      end
    end

    factory :invalid_cart do
      items do
        e = FactoryGirl.create(:equipment_model)
        FactoryGirl.create(:equipment_item, equipment_model: e)
        { e.id => 1 }
      end

      start_date Time.zone.today
      due_date do
        Time.zone.today\
        + EquipmentModel.find(items.keys.first).category.max_checkout_length\
        + 2.days
      end
    end
  end
end
