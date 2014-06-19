class SetUserViewmodeToRole < ActiveRecord::Migration
  def up
    User.connection.execute("update users set view_mode=role")
  end

  def down
  end
end
