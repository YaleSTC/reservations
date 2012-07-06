module EquipmentModelsHelper
  def bar_progress
    define_width
    @width_percentage = number_to_percentage(@width * 100 || "0%", :precision => 0)
  end
  
  def progress_color
    define_width  
    if @width > (1/3 * 2)
      @color = "progress-success"
    elsif @width > 1/3
      @color = "progress-warning"
    elsif @width < 1/3
      @color = "progress-danger"
    end
  end
  
  private
  
  def define_width
    if @equipment_model.equipment_objects.size > 0
      @width = (@equipment_model.available?(cart.start_date..cart.due_date).to_f) / @equipment_model.equipment_objects.size.to_f     
    else
      @width = 0
    end
  end
end
