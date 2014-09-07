class RemoveDeletedAtFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :deleted_at
  end

  def down
    add_column :users, :deleted_at, :datetime
  end
end
