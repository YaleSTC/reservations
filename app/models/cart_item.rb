class CartItem
  attr_accessor :equipment_model, :quantity
  
  def initialize(equipment_model)
    @equipment_model = equipment_model
    @quantity = 1
  end
  
  def increment_quantity
    @quantity += 1
  end
  
  def decrement_quantity
    if @quantity > 0
      @quantity -= 1
    end
  end
  
  def details
    detail = {
      :equipment_model => @equipment_model,
      :quantity => @quantity
    }
  end
  
  def name
    @equipment_model.name
  end
  
  def available?(range_of_dates)
    range_of_dates.each do |day|
      return false if equipment_model.available_count(day) < quantity
    end
    true
  end
end
