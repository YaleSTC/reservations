class RenameLoginToUsernameForUsers < ActiveRecord::Migration
  def change
    rename_column :users, :login, :username
  end
end
