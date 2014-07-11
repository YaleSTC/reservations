require 'benchmark'

cart = Cart.new
cart.due_date = '2014-07-24'
cart.add_item(EquipmentModel.find(16))

cart.add_item(EquipmentModel.find(15))

cart.add_item(EquipmentModel.find(14))
n = 100

puts Benchmark.measure {
  n.times do
    cart.validate_items
  end
}
