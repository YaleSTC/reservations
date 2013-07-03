module ActivationHelper

  def activateParents(current_item)
    if (current_item.class == EquipmentObject) #Equipment Objects have EMs and Categories that may need to be reactivated
      #Reactivate the current item's category and/or Equipment Model if deactivated
      category = Category.find(EquipmentModel.find(current_item.equipment_model_id).category_id)
      category.revive if category.deleted_at
      em = EquipmentModel.find(current_item.equipment_model_id)
      em.revive if em.deleted_at
    elsif (current_item.class == EquipmentModel) #EMs have Categories that may need to be reactivated
      #Reactivate the current item's category
      category = Category.find(current_item.category_id)
      category.revive if category.deleted_at
    end
  end

end