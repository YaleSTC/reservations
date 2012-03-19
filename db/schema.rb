# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110401155438) do

  create_table "accessories_equipment_models", :force => true do |t|
    t.integer  "accessory_id"
    t.integer  "equipment_model_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "max_per_user"
    t.integer  "max_checkout_length"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order"
  end

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.string   "data_file_name"
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "equipment_model_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equipment_models", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "late_fee",            :precision => 10, :scale => 2
    t.decimal  "replacement_fee",     :precision => 10, :scale => 2
    t.integer  "max_per_user"
    t.boolean  "active",                                             :default => true
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "checkout_procedures"
    t.text     "checkin_procedures"
    t.boolean  "active",                                             :default => true
  end

  create_table "equipment_models_reservations", :force => true do |t|
    t.integer  "equipment_model_id"
    t.integer  "reservation_id"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equipment_objects", :force => true do |t|
    t.string   "name"
    t.string   "serial"
    t.boolean  "active",             :default => true
    t.integer  "equipment_model_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equipment_objects_reservations", :id => false, :force => true do |t|
    t.integer  "equipment_object_id"
    t.integer  "reservation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reservations", :force => true do |t|
    t.integer  "equipment_model_id"
    t.integer  "equipment_object_id"
    t.integer  "reserver_id"
    t.integer  "checkout_handler_id"
    t.integer  "checkin_handler_id"
    t.datetime "start_date"
    t.datetime "due_date"
    t.datetime "checked_out"
    t.datetime "checked_in"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "var",        :null => false
    t.text     "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["var"], :name => "index_settings_on_var"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "nickname"
    t.string   "phone"
    t.string   "email"
    t.string   "affiliation"
    t.boolean  "is_banned",          :default => false
    t.boolean  "is_admin",           :default => false
    t.boolean  "is_checkout_person", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
