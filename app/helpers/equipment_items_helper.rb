# frozen_string_literal: true
module EquipmentItemsHelper
  def add_equipment_item_link(name)
    # TODO: link_to_function is deprecated and this can probably be removed
    link_to_function name do |page|
      page.insert_html :bottom, :equipment_model_table,
                       partial: 'equipment_item',
                       item: EquipmentItem.new
    end
  end
end
