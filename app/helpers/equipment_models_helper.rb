# frozen_string_literal: true

module EquipmentModelsHelper
  def evaluate_img_presence(equipment_model)
    if equipment_model.photo.attached?
      equipment_model.photo.variant(resize: '150x150')
    else
      'no-image-260.gif'
    end
  end

  def available_item_select_options(em)
    items = em.equipment_items.active.select(&:available?).sort_by(&:name)
    items.collect do |item|
      "<option value=#{sanitize item.id.to_s}>"\
        "#{sanitize item.name}</option>"
    end.join
  end
end
