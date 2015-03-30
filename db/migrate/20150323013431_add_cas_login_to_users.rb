class AddCasLoginToUsers < ActiveRecord::Migration
  def change
    add_column :users, :cas_login, :string
  end
end
