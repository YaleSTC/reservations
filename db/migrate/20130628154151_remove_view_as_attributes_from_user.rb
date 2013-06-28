class RemoveViewAsAttributesFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :adminmode
    remove_column :users, :checkoutpersonmode
    remove_column :users, :normalusermode
    remove_column :users, :bannedmode

    add_column :users, :view_mode, :string, :default => 'admin'
  end

  def down
    add_column :users, :adminmode, :boolean, :default => true
    add_column :users, :checkoutpersonmode, :boolean, :default => false
    add_column :users, :normalusermode, :boolean, :default => false
    add_column :users, :bannedmode, :boolean, :default => false

    remove_column :users, :view_mode
  end
end
