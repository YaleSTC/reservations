class DropSettingsTable < ActiveRecord::Migration
  def up
    drop_table :settings
  end

  def down
    create_table "settings", :force => true do |t|
      t.string   "var",                      :null => false
      t.text     "value"
      t.integer  "thing_id"
      t.string   "thing_type", :limit => 30
      t.datetime "created_at",               :null => false
      t.datetime "updated_at",               :null => false
    end
  end
end
