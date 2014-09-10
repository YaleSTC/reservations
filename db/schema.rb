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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140909230819) do

  create_table "announcements", force: true do |t|
    t.text     "message"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "app_configs", force: true do |t|
    t.boolean  "upcoming_checkin_email_active",                      default: true
    t.boolean  "reservation_confirmation_email_active",              default: true
    t.string   "site_title",                                                         null: false
    t.string   "admin_email",                                                        null: false
    t.string   "department_name",                                                    null: false
    t.string   "contact_link_location",                                              null: false
    t.string   "home_link_text",                                                     null: false
    t.string   "home_link_location",                                                 null: false
    t.integer  "default_per_cat_page"
    t.text     "upcoming_checkin_email_body",                                        null: false
    t.text     "overdue_checkin_email_body",                                         null: false
    t.boolean  "overdue_checkin_email_active",                       default: true
    t.text     "terms_of_service",                                                   null: false
    t.string   "favicon_file_name"
    t.string   "favicon_content_type"
    t.integer  "favicon_file_size"
    t.datetime "favicon_updated_at"
    t.boolean  "delete_missed_reservations",                         default: true
    t.text     "deleted_missed_reservation_email_body",                              null: false
    t.boolean  "send_notifications_for_deleted_missed_reservations", default: true
    t.boolean  "checkout_persons_can_edit",                          default: false
    t.boolean  "require_phone",                                      default: false
    t.boolean  "viewed",                                             default: true
    t.boolean  "override_on_create",                                 default: false
    t.boolean  "override_at_checkout",                               default: false
    t.integer  "blackout_exp_time"
    t.text     "request_text",                                                       null: false
  end

  create_table "blackouts", force: true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.text     "notice"
    t.integer  "created_by"
    t.text     "blackout_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "set_id"
  end

  create_table "categories", force: true do |t|
    t.string   "name"
    t.integer  "max_per_user"
    t.integer  "max_checkout_length"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order"
    t.datetime "deleted_at"
    t.integer  "max_renewal_times"
    t.integer  "max_renewal_length"
    t.integer  "renewal_days_before_due"
  end

  create_table "checkin_procedures", force: true do |t|
    t.integer  "equipment_model_id"
    t.string   "step"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "checkout_procedures", force: true do |t|
    t.integer  "equipment_model_id"
    t.string   "step"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "equipment_models", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "late_fee",                   precision: 10, scale: 2
    t.decimal  "replacement_fee",            precision: 10, scale: 2
    t.integer  "max_per_user"
    t.boolean  "active",                                              default: true
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
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
    t.integer  "max_checkout_length"
  end

  create_table "equipment_models_associated_equipment_models", id: false, force: true do |t|
    t.integer "equipment_model_id"
    t.integer "associated_equipment_model_id"
  end

  create_table "equipment_models_requirements", id: false, force: true do |t|
    t.integer "requirement_id",     null: false
    t.integer "equipment_model_id", null: false
  end

  create_table "equipment_objects", force: true do |t|
    t.string   "name"
    t.string   "serial"
    t.boolean  "active",              default: true
    t.integer  "equipment_model_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "deactivation_reason"
  end

  create_table "requirements", force: true do |t|
    t.integer  "equipment_model_id"
    t.string   "contact_name"
    t.string   "contact_info"
    t.datetime "deleted_at"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
  end

  create_table "reservations", force: true do |t|
    t.integer  "reserver_id"
    t.integer  "checkout_handler_id"
    t.integer  "checkin_handler_id"
    t.datetime "start_date"
    t.datetime "due_date"
    t.datetime "checked_out"
    t.datetime "checked_in"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "equipment_model_id"
    t.integer  "equipment_object_id"
    t.text     "notes"
    t.boolean  "notes_unsent",        default: true
    t.integer  "times_renewed"
    t.string   "approval_status",     default: "auto"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "users", force: true do |t|
    t.string   "login"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "nickname",                  default: "",       null: false
    t.string   "phone"
    t.string   "email"
    t.string   "affiliation"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "terms_of_service_accepted"
    t.string   "view_mode",                 default: "admin"
    t.string   "role",                      default: "normal"
  end

  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree

  create_table "users_requirements", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "requirement_id"
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
