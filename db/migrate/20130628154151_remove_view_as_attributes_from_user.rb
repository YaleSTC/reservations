class RemoveViewAsAttributesFromUser < ActiveRecord::Migration
  def up
    add_column :users, :view_mode, :string, :default => 'admin'

    User.all.each do |user|
      if user.bannedmode
        user.view_mode = 'banned'
      elsif user.checkoutpersonmode
        user.view_mode = 'checkout'
      elsif user.normalusermode
        user.view_mode = 'normal'
      else
        user.view_mode = 'admin'
      end
      user.save!
    end

    remove_column :users, :adminmode
    remove_column :users, :checkoutpersonmode
    remove_column :users, :normalusermode
    remove_column :users, :bannedmode

  end

  def down
    add_column :users, :adminmode, :boolean, :default => true
    add_column :users, :checkoutpersonmode, :boolean, :default => false
    add_column :users, :normalusermode, :boolean, :default => false
    add_column :users, :bannedmode, :boolean, :default => false

    User.all.each do |user|
      if user.view_mode == 'admin'
        user.adminmode = true
      elsif user.view_mode == 'checkout'
        user.adminmode = false
        user.checkoutpersonmode = true
      elsif user.view_mode == 'banned'
        user.adminmode = false
        user.bannedmode = true
      elsif user.view_mode == 'normal'
        user.adminmode = false
        user.normalusermode = true
      end
      user.save!
    end

    remove_column :users, :view_mode
  end
end
