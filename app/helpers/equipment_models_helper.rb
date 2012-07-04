module EquipmentModelsHelper
  def bar_progress
    width = @equipment_model.equipment_objects.size != 0 ? (((@equipment_model.available?(cart.start_date..cart.due_date) || "0").to_i) / 
    @equipment_model.equipment_objects.size) * 100 : 0
    @width_percentage = number_to_percentage(width || "0%", :precision => 0)
  end
  
  def progress_color
    width = @equipment_model.equipment_objects.size != 0 ? (((@equipment_model.available?(cart.start_date..cart.due_date) || "0").to_i) / 
    @equipment_model.equipment_objects.size) * 100 : 0
    binding.pry
    a_third = (100 / 3)
    
    if width > (a_third * 2)
      @color = "progress-success"
    elsif width > a_third
      @color = "progress-warning"
    elsif width < a_third
      @color = "progress-danger"
    end
  end
end
