class CreateBlackOuts < ActiveRecord::Migration
  def change
    create_table :black_outs do |t|
      t.integer :equipment_model_id
      t.datetime :start_date
      t.datetime :end_date
      t.text :notice
      t.integer :created_by
      t.text :black_out_type

      t.timestamps
    end
  end
end
