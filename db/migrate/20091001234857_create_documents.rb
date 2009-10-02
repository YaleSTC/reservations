class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string :name
      t.string :data_file_name
      t.string :data_content_type
      t.integer :data_file_size
      t.references :equipment_model
      t.timestamps
    end
  end
  
  def self.down
    drop_table :documents
  end
end
