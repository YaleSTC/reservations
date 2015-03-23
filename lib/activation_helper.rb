module ActivationHelper
  def activate_parents(current_item)
    # Equipment Items have EMs and Categories that may need to be
    # reactivated
    if (current_item.class == EquipmentItem)
      # Reactivate the current item's category and/or Equipment Model if
      # deactivated
      category = Category.find(
        EquipmentModel.find(current_item.equipment_model_id).category_id)
      category.revive if category.deleted_at
      em = EquipmentModel.find(current_item.equipment_model_id)
      if em.deleted_at
        em.revive
        # reactivate all checkin and checkout procedures if reviving an
        # equipment model
        activate_procedures(em)
      end
    # EMs have Categories and checkin/checkout procedures that may need to be
    # reactivated
    elsif (current_item.class == EquipmentModel)
      # Reactivate the current item's category
      category = Category.find(current_item.category_id)
      category.revive if category.deleted_at
      # Reactivate all checkin and checkout procedures
      activate_procedures(current_item)
    end
  end

  def activate_procedures(em)
    em.checkout_procedures.each(&:revive)
    em.checkin_procedures.each(&:revive)
  end
end
