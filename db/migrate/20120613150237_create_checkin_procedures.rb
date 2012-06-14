class CreateCheckinProcedures < ActiveRecord::Migration
  def up
    create_table :checkin_procedures do |t|
      t.references :equipment_model
      t.string :step
      t.timestamps
    end
  end

  def down
    drop_table :checkin_procedures
  end
end
