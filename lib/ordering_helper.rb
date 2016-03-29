# frozen_string_literal: true
class OrderingHelper
  attr_reader :equipment_model, :category_id, :category_count, :ordering

  def initialize(equipment_model)
    @equipment_model = equipment_model
    @category_id = equipment_model.category_id
    @category_count = equipment_model.category.active_model_count
    @ordering = equipment_model.ordering
  end

  def assign_order
    equipment_model.update_attribute('ordering', category_count + 1)
  end

  def successor
    EquipmentModel.where(category_id: category_id,
                         ordering: ordering - 1,
                         deleted_at: nil).first
  end

  def predecessor
    EquipmentModel.where(category_id: category_id,
                         ordering: ordering + 1,
                         deleted_at: nil).first
  end

  def up
    return unless ordering > 1
    target = successor
    equipment_model.update_attribute('ordering', ordering - 1)
    target.update_attribute('ordering', ordering)
  end

  def down
    return unless ordering < category_count
    target = predecessor
    equipment_model.update_attribute('ordering', ordering + 1)
    target.update_attribute('ordering', ordering)
  end

  def successors
    EquipmentModel.where(category_id: category_id)
                  .where('ordering > ?', ordering)
  end

  def deactivate_order
    ms = successors
    ms.each do |m|
      m.update_attribute('ordering', m.ordering - 1)
    end
    equipment_model.update_attribute('ordering', -1)
  end
end
