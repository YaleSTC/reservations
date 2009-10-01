class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login
      t.string :first_name
      t.string :last_name
      t.string :nickname
      t.string :phone
      t.string :email
      t.string :affiliation
      t.boolean :is_banned
      t.timestamps
    end
  end
  
  def self.down
    drop_table :users
  end
end
