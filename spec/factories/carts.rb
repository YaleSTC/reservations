FactoryGirl.define do
  factory :cart do
    reserver_id { FactoryGirl.create(:user).id }
    start_date { Date.today }
    due_date { Date.tomorrow }
    items {}

    factory :cart_with_items do
      if EquipmentModel.blank?
        @model = FactoryGirl.create(:equipment_model)
      else
        @model = EquipmentModel.first
      end
      items {{ "1" => 1} }
    end

    factory :invalid_cart do
      if EquipmentModel.blank?
        @model = FactoryGirl.create(:equipment_model)
      else
        @model = EquipmentModel.first
      end
      items { {"1" => 1} }
      start_date Date.today
      due_date Date.today + 100.day

    end
  end
end
