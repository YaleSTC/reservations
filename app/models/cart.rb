class Cart
  attr_reader :items, :start_date, :due_date
  
  def initialize
    @items = []
    @start_date = Date.today
    @due_date = Date.today
  end
  
  def add_equipment_model(equipment_model)
    current_item = @items.find {|item| item.equipment_model == equipment_model}
    if current_item
      current_item.increment_quantity
    else
      current_item = CartItem.new(equipment_model)
      @items << current_item
    end
    current_item
  end
  
  def remove_equipment_model(equipment_model)
    current_item = @items.find {|item| item.equipment_model == equipment_model}
    current_item.decrement_quantity
    if current_item.quantity == 0
      @items.delete(current_item)
    end
    current_item
  end
  
  def get_cart_items
    items = []
    @items.each do |item|
      items << item.details
    end
    items
  end
  
  def total_items
    @items.sum{ |item| item.quantity }
  end
  
  def empty?
    @items.empty?
  end
  
  def available?
    return false if start_date.nil? or due_date.nil?
    @items.each do |item|
      return false if !item.available?(start_date..due_date)
    end
    return true
  end
  
  def set_start_date(date)
    @start_date = date  
  end
  
  def set_due_date(date)
    @due_date = date  
  end
end