module EquipmentObjectsHelper
  def add_equipment_object_link(name)
    #TODO link_to_function is deprecated and this can probably be removed
    link_to_function name do |page|
      page.insert_html :bottom, :equipment_model_table, :partial => 'equipment_object', :object => EquipmentObject.new
    end
  end
end
