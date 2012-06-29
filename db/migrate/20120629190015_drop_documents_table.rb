class DropDocumentsTable < ActiveRecord::Migration
  def up
    drop_table :documents
  end

  def down
    create_table :documents do |t|
      t.string :name
      t.string :data_file_name
      t.string :data_content_type
      t.integer :data_file_size
      t.references :equipment_model
      t.timestamps
    end
  end
end
