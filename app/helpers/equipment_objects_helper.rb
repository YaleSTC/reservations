module EquipmentObjectsHelper
  def add_equipment_object_link(name)
    link_to_function name do |page|
      page.insert_html :bottom, :equipment_model_table, :partial => 'equipment_object', :object => EquipmentObject.new
    end
  end
end
