# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def deactivateChildren(currentModel)
      @objects_class = currentModel.class.name.constantize #Find out the class of the object we are going to deactivate
        @all_associations = @objects_class.reflect_on_all_associations(:has_many).collect(&:name).each do |association| #For every child object of the parent:
            if (association == :equipment_models) #Deactivate any Equipment Models associated with currentModel
               EquipmentModel.not_deleted.where(:category_id => currentModel.id).each do |child| 
                  deactivateChildren(child)
               end
            end
            if association == :equipment_objects #Deactivate any Equipment Objects associated with currentModel
               EquipmentObject.not_deleted.where(:equipment_model_id => currentModel.id).each do |child| 
                  deactivateChildren(child)
               end
            end
         end
      currentModel.destroy
  end

  def activateParents(currentModel)
    if (currentModel.class == EquipmentObject) #Equipment Objects have EMs and Categories that may need to be reactivated
      EquipmentModel.find(currentModel.equipment_model_id).revive #Reactivate the EM
      Category.find(EquipmentModel.find(currentModel.equipment_model_id).category_id).revive #Reactivate the Category
    elsif (currentModel.class == EquipmentModel) #EMs have Categories that may need to be reactivated
      Category.find(currentModel.category_id).revive #Reactivate the category
    end
  end

end
