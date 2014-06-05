class AddVisibleToAnnouncements < ActiveRecord::Migration
  def change
    add_column :announcements, :visible_to, :string
  end
end
