class RemovePaperclipColumns < ActiveRecord::Migration[6.0]
  def change
    # Remove Paperclip columns from EquipmentModel table
    remove_column :equipment_models, :photo_file_name, :string
    remove_column :equipment_models, :photo_content_type, :string
    remove_column :equipment_models, :photo_file_size, :integer
    remove_column :equipment_models, :photo_updated_at, :datetime
    remove_column :equipment_models, :documentation_file_name, :string
    remove_column :equipment_models, :documentation_content_type, :string
    remove_column :equipment_models, :documentation_file_size, :integer
    remove_column :equipment_models, :documentation_updated_at, :datetime

    # Remove Paperclip columns from AppConfig table
    remove_column :app_configs, :favicon_file_name, :string
    remove_column :app_configs, :favicon_content_type, :string
    remove_column :app_configs, :favicon_file_size, :integer
    remove_column :app_configs, :favicon_updated_at, :datetime
  end
end
