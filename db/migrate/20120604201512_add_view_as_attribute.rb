class AddViewAsAttribute < ActiveRecord::Migration
  def self.up
    add_column :users, :adminmode, :boolean, :default => true
    add_column :users, :checkoutpersonmode, :boolean, :default => false
    add_column :users, :normalusermode, :boolean, :default => false
    add_column :users, :bannedmode, :boolean, :default => false
  end

  def self.down
    remove_column :users, :adminmode
    remove_column :users, :checkoutpersonmode
    remove_column :users, :normalusermode
    remove_column :users, :bannedmode
  end
end
