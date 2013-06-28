class FixUsersColumnName < ActiveRecord::Migration
  def change
  	rename_column :users, :type, :role
  end
end
