class CreateRequirements < ActiveRecord::Migration
  def self.up
    create_table :requirements do |t|
      t.integer :equipment_model_id
      t.string :contact_name
      t.string :contact_info
      t.datetime :deleted_at
      t.text :notes
      t.timestamps
    end
  end

  def self.down
    drop_table :requirements
  end
end
