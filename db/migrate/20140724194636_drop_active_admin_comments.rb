class DropActiveAdminComments < ActiveRecord::Migration
  def up
    drop_table :active_admin_comments
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
