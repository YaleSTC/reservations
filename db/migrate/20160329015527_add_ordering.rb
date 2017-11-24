class AddOrdering < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:equipment_models, :ordering)
  	 add_column :equipment_models, :ordering, :integer, :null => false
    end
  	# store ActiveRecord connection to run queries
    conn = ActiveRecord::Base.connection

    # go through all categories
    models = conn.exec_query('SELECT * FROM equipment_models WHERE '\
                             'active = TRUE')
  	ord = 1
  	models.each do |m|
      conn.execute("UPDATE equipment_models SET ordering = "\
                   "#{ord} WHERE id = #{m['id']}")
  	  ord += 1
  	end
  end
  def down
  	remove_column :equipment_models, :ordering
  end
end

