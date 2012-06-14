class CreateCheckoutProcedures < ActiveRecord::Migration
  def up
    create_table :checkout_procedures do |t|
      t.references :equipment_model
      t.string :step
      t.timestamps
    end
  end

  def down
    drop_table :checkout_procedures
  end
end
