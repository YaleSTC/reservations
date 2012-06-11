# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def deactivateX(a)
      @objects_class = a.class.name.constantize #Find out the class of the object we are going to deactivate
        @all_associations = @objects_class.reflect_on_all_associations(:has_many).collect(&:name).each do |x| #For every child object of the parent:
            if (x == :equipment_models)
               EquipmentModel.not_deleted.where(:category_id => a.id).each do |y| #Deactivate any Equipment Models that belong to a particular category
                  deactivateX(y)
               end
            end
            if x == :equipment_objects
               EquipmentObject.not_deleted.where(:equipment_model_id => a.id).each do |y| #Deactivate any Equipment Objects that belong to a particular Equipment Model
                  deactivateX(y)
               end
            end
         end
      a.destroy
  end

end
