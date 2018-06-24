class FixOverdueCount < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        conn = ActiveRecord::Base.connection
        conn.exec_query('SELECT * FROM equipment_models').each do |em|
          overdue = conn.exec_query('SELECT * FROM reservations WHERE '\
                                    "equipment_model_id = #{em['id']} "\
                                    'AND checked_in IS NULL '\
                                    'AND overdue = TRUE').count
          conn.execute('UPDATE equipment_models SET overdue_count = '\
                       "#{overdue} WHERE id = #{em['id']}")
        end
      end
    end
  end
end
