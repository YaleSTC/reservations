# frozen_string_literal: true

module EquipmentModelsHelper
  def evaluate_img_presence(equipment_model)
    if equipment_model.photo.exists?
      equipment_model.photo.url(:small)
    else
      'no-image-260.gif'
    end
  end

  def display_order(em)
    em.category_ordering.index(em.ordering) + 1
  end

  def available_item_select_options(em)
    @items ||= em.equipment_items.includes(:reservations).active
                 .select(&:available?).sort_by(&:name)
    @str ||= @items.collect do |item|
      "<option value=#{sanitize item.id.to_s}>"\
        "#{sanitize item.name}</option>"
    end.join
  end
end
