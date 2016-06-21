# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')
require Rails.root.join('spec/support/mockers/category_mock.rb')
require Rails.root.join('spec/support/mockers/equipment_item_mock.rb')

class EquipmentModelMock < Mocker
  def self.klass
    EquipmentModel
  end

  def self.klass_name
    'EquipmentModel'
  end

  private

  def with_item(item:)
    with_items(items: [item])
  end

  def with_items(items: nil, count: 1)
    items ||= Array.new(count) { EquipmentItemMock.new }
    parent_has_many(mocked_children: items, parent_sym: :equipment_model,
                    child_sym: :equipment_items)
  end

  def with_category(cat: nil)
    cat ||= CategoryMock.new
    child_of_has_many(mocked_parent: cat, parent_sym: :category,
                      child_sym: :equipment_models)
  end
end
