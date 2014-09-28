class AddCsvImportToEquipmentStuff < ActiveRecord::Migration
  def change
  	add_column :categories, :csv_import, :boolean, :default => false, :null => false
  	add_column :equipment_models, :csv_import, :boolean, :default => false, :null => false
  	add_column :equipment_objects, :csv_import, :boolean, :default => false, :null => false
  end
end
