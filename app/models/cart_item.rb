class CartItem
  attr_reader :equipment_model, :quantity
  
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
end
