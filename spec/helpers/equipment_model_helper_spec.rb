# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EquipmentModelsHelper do
  describe '.available_item_select_options' do
    it 'makes a string listing the available items' do
      model = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:checked_out_reservation, equipment_model: model)
      item = FactoryGirl.create(:equipment_item, equipment_model: model)
      expect(available_item_select_options(model)).to \
        eq("<option value=#{item.id}>#{item.name}</option>")
    end
  end
end
