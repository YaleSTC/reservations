class AddDeletedDateToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :deleted_at, :string
    add_column :equipment_objects, :deleted_at, :string
    add_column :equipment_models, :deleted_at, :string
    add_column :categories, :deleted_at, :string
  end

  def self.down
    remove_column :users, :deleted_at, :string
    remove_column :equipment_objects, :deleted_at, :string
    remove_column :equipment_models, :deleted_at, :string
    remove_column :categories, :deleted_at, :string
  end
end
