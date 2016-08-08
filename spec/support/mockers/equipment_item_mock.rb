# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')
require Rails.root.join('spec/support/mockers/equipment_model_mock.rb')

class EquipmentItemMock < Mocker
  def self.klass
    EquipmentItem
  end

  def self.klass_name
    'EquipmentItem'
  end

  private

  def with_model(model: nil)
    model ||= EquipmentModelMock.new
    child_of_has_many(mocked_parent: model, parent_sym: :equipment_model,
                      child_sym: :equipment_items)
  end
end
