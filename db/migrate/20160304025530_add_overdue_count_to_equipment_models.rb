class AddOverdueCountToEquipmentModels < ActiveRecord::Migration

  def self.up
    add_column :equipment_models, :overdue_count, :integer, :null => false, :default => 0

    conn = ActiveRecord::Base.connection

    conn.exec_query('select * from equipment_models').each do |e|
      overdue = conn.exec_query("select * from reservations where
                                reservation.equipment_model.id = #{e['id']}
                                AND overdue = TRUE").count
      conn.execute('UPDATE equipment_models SET overdue_count = '\
                   "#{overdue} WHERE equipment_model.id = #{e['id']}")
    end
  end

  def self.down
    remove_column :equipment_models, :overdue_count
  end

end
