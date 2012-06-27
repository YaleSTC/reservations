class CreateBlackOuts < ActiveRecord::Migration
  def change
    create_table :black_outs do |t|
      t.integer :equipment_model
      t.datetime :start_date
      t.datetime :end_date
      t.text :notice
      t.integer :created_by
      t.integer :type

      t.timestamps
    end
  end
end
