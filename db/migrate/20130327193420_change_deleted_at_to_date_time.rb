class ChangeDeletedAtToDateTime < ActiveRecord::Migration
  def change
    change_column :users, :deleted_at, :datetime
    change_column :equipment_objects, :deleted_at, :datetime
    change_column :equipment_models, :deleted_at, :datetime
    change_column :categories, :deleted_at, :datetime
  end
end
