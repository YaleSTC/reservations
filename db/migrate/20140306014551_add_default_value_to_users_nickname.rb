class AddDefaultValueToUsersNickname < ActiveRecord::Migration
  def up
    User.all.each do |user|
      if user.nickname.nil?
        user.nickname = ''
        user.save!
      end
    end
  	change_column :users, :nickname, :string, :default => '', :null => false
  end
  
  def down
    change_column :users, :nickname, :string
  end
end
