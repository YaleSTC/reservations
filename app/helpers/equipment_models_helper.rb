module EquipmentModelsHelper
  def bar_progress
    define_width
    @width_percentage = number_to_percentage(@width * 100 || "0%", :precision => 0)
  end

  def progress_color
    define_width
    if @width > (2.0 / 3.0)
      @color = "progress-success"
    elsif @width <= (2.0 / 3.0) && @width > (1.0 / 3.0)
      @color = "progress-warning"
    else
      @color = "progress-danger"
    end
  end

  def evaluate_img_presence equipment_model
    if equipment_model.photo.exists?
      equipment_model.photo.url(:small)
    else
      "no-image-260.gif"
    end
  end

  private

  def define_width
    if @equipment_model.equipment_objects.size > 0
      @width = (@equipment_model.num_available(cart.start_date, cart.due_date).to_f) / @equipment_model.equipment_objects.size.to_f
    else
      @width = 0
    end
  end
end
