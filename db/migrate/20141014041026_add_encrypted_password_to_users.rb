class AddEncryptedPasswordToUsers < ActiveRecord::Migration
  def change
    add_column :users, :encrypted_password, :string, :null => false, :default => '', :limit => 128
  end
end
