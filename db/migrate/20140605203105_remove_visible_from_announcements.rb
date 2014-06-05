class RemoveVisibleFromAnnouncements < ActiveRecord::Migration
  def up
    remove_column :announcements, :visible_to
  end

  def down
    add_column :announcements, :visible_to, :string
  end
end
