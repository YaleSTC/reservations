# frozen_string_literal: true
require Rails.root.join('spec/support/mockers/mocker.rb')
require Rails.root.join('spec/support/mockers/equipment_model_mock.rb')

class CategoryMock < Mocker
  def self.klass
    Category
  end

  def self.klass_name
    'Category'
  end

  private

  def with_equipment_models(models: nil, count: 1)
    models ||= Array.new(count) { EquipmentModelMock.new }
    parent_has_many(mocked_children: models, parent_sym: :category,
                    child_sym: :equipment_models)
  end
end
