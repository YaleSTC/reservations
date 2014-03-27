class AddDefaultValueToUsersNickname < ActiveRecord::Migration
  def self.up
  	change_column :users, :nickname, :string, :default => '', :null => false
  end
end
