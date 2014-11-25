class AddRecoverableToUser < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
    end
  end
end
