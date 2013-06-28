class CombineTypeColumnsInUsersTable < ActiveRecord::Migration
  def up
  	remove_column :users, :is_banned
  	remove_column :users, :is_admin
  	remove_column :users, :is_checkout_person

  	add_column :users, :type, :string, :default => 'normal'
  end

  def down
  	add_column :users, :is_banned, :boolean, :default => false
    add_column :users, :is_admin, :boolean, :default => false
    add_column :users, :is_checkout_person, :boolean, :default => false

    remove_column :users, :type
  end
end
