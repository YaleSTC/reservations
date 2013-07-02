class CombineTypeColumnsInUsersTable < ActiveRecord::Migration
  def up
    add_column :users, :role, :string, :default => 'normal'

    User.each do |user|
      if user.is_banned
        user.role = 'banned'
      elsif user.is_admin
        user.role = 'admin'
      elsif user.is_checkout_person
        user.role = 'checkout'
      else
        user.role = 'normal'
      end
      user.save!
    end

  	remove_column :users, :is_banned
  	remove_column :users, :is_admin
  	remove_column :users, :is_checkout_person

  end

  def down
  	add_column :users, :is_banned, :boolean, :default => false
    add_column :users, :is_admin, :boolean, :default => false
    add_column :users, :is_checkout_person, :boolean, :default => false

    User.each do |user|
      if user.role == 'banned'
        user.is_banned = true
      elsif user.role == 'admin'
        user.is_admin = true
      elsif user.role == 'checkout'
        user.is_checkout_person = true
      end
      user.save!
    end

    remove_column :users, :role
  end
end
