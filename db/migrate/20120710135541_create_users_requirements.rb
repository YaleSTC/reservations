class CreateUsersRequirements < ActiveRecord::Migration
  def change
    create_table :users_requirements, :id => false do |t|
      t.integer :user_id
      t.integer :requirement_id

    end
  end
end
