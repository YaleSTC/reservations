class FillInOrderings < ActiveRecord::Migration
  def up
  	cats = EquipmentModel.uniq.pluck(:category_id)
  	cats.each do |c|
  		models = EquipmentModel.where(category_id: c, deleted_at: nil)
  		ord = 1
  		models.each do |m|
  			m['ordering'] = ord
  			ord += 1
  		end
  	end 
  end
  def down
  	EquipmentModel.all.each do |m| 
  		m.update_attribute("ordering", nil)
  	end
  end
end
