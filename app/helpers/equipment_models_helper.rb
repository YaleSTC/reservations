module EquipmentModelsHelper
  def bar_progress
    width = ((@equipment_model.available?(cart.start_date..cart.due_date) || "0").to_i) / @equipment_model.equipment_objects.size
    @width_percentage = number_to_percentage(width * 100, :precision => 0)
  end
end
