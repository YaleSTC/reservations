class CreateAnnouncements < ActiveRecord::Migration
  def change
    create_table :announcements do |t|
      t.text :message
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end
  end
end
