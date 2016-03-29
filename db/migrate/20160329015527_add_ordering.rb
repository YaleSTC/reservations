class AddOrdering < ActiveRecord::Migration
  def up
  	puts column_exists?(:equipment_models, :ordering)
  	add_column :equipment_models, :ordering, :integer, :null => false

  	# store ActiveRecord connection to run queries
    conn = ActiveRecord::Base.connection

    # go through all categories
    conn.exec_query('select * from categories').each do |cat|
    	models = conn.exec_query("select * from reservations where category_id = #{cat.id} and deleted_at is not null")
  		ord = 1
  		models.each do |m|
  			m['ordering'] = ord
  			ord += 1
  		end
  	end
  end
  def down
  	remove_column :equipment_models, :ordering
  	puts column_exists?(:equipment_models, :ordering)
  end
end

