class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name
      t.integer :max_per_user
      t.integer :max_checkout_length
      t.timestamps
    end
  end
  
  def self.down
    drop_table :categories
  end
end
