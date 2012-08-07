module ActivationHelper
  
    def deactivateChildren(current_model)
      @objects_class = current_model.class.name.constantize #Find out the class of the object we are going to deactivate
        @all_associations = @objects_class.reflect_on_all_associations(:has_many).collect(&:name).each do |association| #For every child object of the parent:
            if (association == :equipment_models) #Deactivate any Equipment Models associated with current_model
               EquipmentModel.where(:category_id => current_model.id).each do |child| 
                  deactivateChildren(child)
               end
            end
            if association == :equipment_objects #Deactivate any Equipment Objects associated with current_model
               EquipmentObject.where(:equipment_model_id => current_model.id).each do |child| 
                  deactivateChildren(child)
               end
            end
         end
      current_model.destroy
  end

  def activateParents(current_model)
    if (current_model.class == EquipmentObject) #Equipment Objects have EMs and Categories that may need to be reactivated
      EquipmentModel.include_deleted.find(current_model.equipment_model_id).revive #Reactivate the EM
      Category.include_deleted.find(EquipmentModel.include_deleted.find(current_model.equipment_model_id).category_id).revive #Reactivate the Category
    elsif (current_model.class == EquipmentModel) #EMs have Categories that may need to be reactivated
      Category.include_deleted.find(current_model.category_id).revive #Reactivate the category
    end
  end

  def activateChildren(current_model)
    if (current_model.class == Category) #Categories have EMs that need to be reactivated, and each of those EMs has EOs that need to be reactivated.
      EquipmentModel.include_deleted.where(category_id: current_model.id).each do |em|
        em.revive
        EquipmentObject.include_deleted.where(equipment_model_id: em.id).each do |eo|
          eo.revive
        end 
      end
    elsif (current_model.class == EquipmentModel) #EMs have EOs that need to be re-activated
      EquipmentObject.include_deleted.where(equipment_model_id: current_model.id).each do |eo|
          eo.revive
        end
    end
  end

end