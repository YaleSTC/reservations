# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120718004311) do

  create_table "app_configs", :force => true do |t|
    t.boolean  "upcoming_checkin_email_active",         :default => true
    t.boolean  "overdue_checkout_email_active",         :default => true
    t.boolean  "reservation_confirmation_email_active", :default => true
    t.string   "site_title"
    t.string   "admin_email"
    t.string   "department_name"
    t.string   "contact_link_location"
    t.string   "home_link_text"
    t.string   "home_link_location"
    t.integer  "default_per_cat_page"
    t.text     "upcoming_checkin_email_body"
    t.text     "overdue_checkout_email_body"
    t.text     "overdue_checkin_email_body"
    t.boolean  "overdue_checkin_email_active",          :default => true
    t.text     "terms_of_service"
    t.string   "favicon_file_name"
    t.string   "favicon_content_type"
    t.integer  "favicon_file_size"
    t.datetime "favicon_updated_at"
  end

  create_table "black_outs", :force => true do |t|
    t.integer  "equipment_model_id"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "notice"
    t.integer  "created_by"
    t.text     "black_out_type"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "max_per_user"
    t.integer  "max_checkout_length"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.integer  "sort_order"
    t.string   "deleted_at"
    t.integer  "max_renewal_times"
    t.integer  "max_renewal_length"
    t.integer  "renewal_days_before_due"
  end

  create_table "checkin_procedures", :force => true do |t|
    t.integer  "equipment_model_id"
    t.string   "step"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "checkout_procedures", :force => true do |t|
    t.integer  "equipment_model_id"
    t.string   "step"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "equipment_models", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "late_fee",                   :precision => 10, :scale => 2
    t.decimal  "replacement_fee",            :precision => 10, :scale => 2
    t.integer  "max_per_user"
    t.boolean  "active",                                                    :default => true
    t.integer  "category_id"
    t.datetime "created_at",                                                                  :null => false
    t.datetime "updated_at",                                                                  :null => false
    t.string   "deleted_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "documentation_file_name"
    t.string   "documentation_content_type"
    t.integer  "documentation_file_size"
    t.datetime "documentation_updated_at"
    t.integer  "max_renewal_times"
    t.integer  "max_renewal_length"
    t.integer  "renewal_days_before_due"
  end

  create_table "equipment_models_associated_equipment_models", :id => false, :force => true do |t|
    t.integer "equipment_model_id"
    t.integer "associated_equipment_model_id"
  end

  create_table "equipment_models_reservations", :force => true do |t|
    t.integer  "equipment_model_id"
    t.integer  "reservation_id"
    t.integer  "quantity"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "equipment_objects", :force => true do |t|
    t.string   "name"
    t.string   "serial"
    t.boolean  "active",             :default => true
    t.integer  "equipment_model_id"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.string   "deleted_at"
  end

  create_table "equipment_objects_reservations", :force => true do |t|
    t.integer  "equipment_object_id"
    t.integer  "reservation_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "requirements", :force => true do |t|
    t.integer  "equipment_model_id"
    t.string   "contact_name"
    t.string   "contact_info"
    t.datetime "deleted_at"
    t.text     "notes"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "reservations", :force => true do |t|
    t.integer  "reserver_id"
    t.integer  "checkout_handler_id"
    t.integer  "checkin_handler_id"
    t.datetime "start_date"
    t.datetime "due_date"
    t.datetime "checked_out"
    t.datetime "checked_in"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "equipment_model_id"
    t.integer  "equipment_object_id"
    t.text     "notes"
    t.boolean  "notes_unsent",        :default => true
    t.integer  "times_renewed"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "nickname"
    t.string   "phone"
    t.string   "email"
    t.string   "affiliation"
    t.boolean  "is_banned",                 :default => false
    t.boolean  "is_admin",                  :default => false
    t.boolean  "is_checkout_person",        :default => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.boolean  "adminmode",                 :default => true
    t.boolean  "checkoutpersonmode",        :default => false
    t.boolean  "normalusermode",            :default => false
    t.boolean  "bannedmode",                :default => false
    t.string   "deleted_at"
    t.boolean  "terms_of_service_accepted"
  end

  create_table "users_requirements", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "requirement_id"
  end

end
