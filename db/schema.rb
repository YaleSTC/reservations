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

ActiveRecord::Schema.define(version: 20150719052612) do

  create_table "announcements", force: :cascade do |t|
    t.text     "message",    limit: 65535
    t.date     "starts_at"
    t.date     "ends_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "app_configs", force: :cascade do |t|
    t.boolean  "upcoming_checkin_email_active",                                    default: true
    t.boolean  "reservation_confirmation_email_active",                            default: true
    t.string   "site_title",                                         limit: 255,                   null: false
    t.string   "admin_email",                                        limit: 255,                   null: false
    t.string   "department_name",                                    limit: 255,                   null: false
    t.string   "contact_link_location",                              limit: 255,                   null: false
    t.string   "home_link_text",                                     limit: 255,                   null: false
    t.string   "home_link_location",                                 limit: 255,                   null: false
    t.integer  "default_per_cat_page",                               limit: 4
    t.text     "upcoming_checkin_email_body",                        limit: 65535,                 null: false
    t.text     "overdue_checkin_email_body",                         limit: 65535,                 null: false
    t.boolean  "overdue_checkin_email_active",                                     default: true
    t.text     "terms_of_service",                                   limit: 65535,                 null: false
    t.string   "favicon_file_name",                                  limit: 255
    t.string   "favicon_content_type",                               limit: 255
    t.integer  "favicon_file_size",                                  limit: 4
    t.datetime "favicon_updated_at"
    t.text     "deleted_missed_reservation_email_body",              limit: 65535,                 null: false
    t.boolean  "send_notifications_for_deleted_missed_reservations",               default: true
    t.boolean  "checkout_persons_can_edit",                                        default: false
    t.boolean  "require_phone",                                                    default: false
    t.boolean  "viewed",                                                           default: true
    t.boolean  "override_on_create",                                               default: false
    t.boolean  "override_at_checkout",                                             default: false
    t.integer  "blackout_exp_time",                                  limit: 4
    t.text     "request_text",                                       limit: 65535,                 null: false
    t.boolean  "enable_renewals",                                                  default: true
    t.boolean  "enable_new_users",                                                 default: true
    t.integer  "res_exp_time",                                       limit: 4
    t.boolean  "enable_guests",                                                    default: true
    t.boolean  "upcoming_checkout_email_active",                                   default: true
    t.text     "upcoming_checkout_email_body",                       limit: 65535
    t.boolean  "notify_admin_on_create",                                           default: false
    t.boolean  "disable_user_emails",                                              default: false
  end

  create_table "blackouts", force: :cascade do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.text     "notice",        limit: 65535
    t.integer  "created_by",    limit: 4
    t.text     "blackout_type", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "set_id",        limit: 4
  end

  create_table "categories", force: :cascade do |t|
    t.string   "name",                    limit: 255
    t.integer  "max_per_user",            limit: 4
    t.integer  "max_checkout_length",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sort_order",              limit: 4
    t.datetime "deleted_at"
    t.integer  "max_renewal_times",       limit: 4
    t.integer  "max_renewal_length",      limit: 4
    t.integer  "renewal_days_before_due", limit: 4
    t.boolean  "csv_import",                          default: false, null: false
  end

  create_table "checkin_procedures", force: :cascade do |t|
    t.integer  "equipment_model_id", limit: 4
    t.string   "step",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "checkout_procedures", force: :cascade do |t|
    t.integer  "equipment_model_id", limit: 4
    t.string   "step",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "equipment_items", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.string   "serial",              limit: 255
    t.boolean  "active",                               default: true
    t.integer  "equipment_model_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "csv_import",                           default: false, null: false
    t.string   "deactivation_reason", limit: 255
    t.text     "notes",               limit: 16777215,                 null: false
  end

  create_table "equipment_models", force: :cascade do |t|
    t.string   "name",                       limit: 255
    t.text     "description",                limit: 65535
    t.decimal  "late_fee",                                 precision: 10, scale: 2
    t.decimal  "replacement_fee",                          precision: 10, scale: 2
    t.integer  "max_per_user",               limit: 4
    t.boolean  "active",                                                            default: true
    t.integer  "category_id",                limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "photo_file_name",            limit: 255
    t.string   "photo_content_type",         limit: 255
    t.integer  "photo_file_size",            limit: 4
    t.datetime "photo_updated_at"
    t.string   "documentation_file_name",    limit: 255
    t.string   "documentation_content_type", limit: 255
    t.integer  "documentation_file_size",    limit: 4
    t.datetime "documentation_updated_at"
    t.integer  "max_renewal_times",          limit: 4
    t.integer  "max_renewal_length",         limit: 4
    t.integer  "renewal_days_before_due",    limit: 4
    t.boolean  "csv_import",                                                        default: false, null: false
    t.integer  "max_checkout_length",        limit: 4
    t.integer  "equipment_items_count",      limit: 4,                              default: 0,     null: false
    t.decimal  "late_fee_max",                             precision: 10, scale: 2, default: 0.0
  end

  create_table "equipment_models_associated_equipment_models", id: false, force: :cascade do |t|
    t.integer "equipment_model_id",            limit: 4
    t.integer "associated_equipment_model_id", limit: 4
  end

  create_table "equipment_models_requirements", id: false, force: :cascade do |t|
    t.integer "requirement_id",     limit: 4, null: false
    t.integer "equipment_model_id", limit: 4, null: false
  end

  create_table "requirements", force: :cascade do |t|
    t.integer  "equipment_model_id", limit: 4
    t.string   "contact_name",       limit: 255
    t.string   "contact_info",       limit: 255
    t.datetime "deleted_at"
    t.text     "notes",              limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description",        limit: 255
  end

  create_table "reservations", force: :cascade do |t|
    t.integer  "reserver_id",         limit: 4
    t.integer  "checkout_handler_id", limit: 4
    t.integer  "checkin_handler_id",  limit: 4
    t.date     "start_date"
    t.date     "due_date"
    t.datetime "checked_out"
    t.datetime "checked_in"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "equipment_model_id",  limit: 4
    t.integer  "equipment_item_id",   limit: 4
    t.text     "notes",               limit: 65535
    t.boolean  "notes_unsent",                      default: false
    t.integer  "times_renewed",       limit: 4
    t.integer  "status",              limit: 4,     default: 0
    t.boolean  "overdue",                           default: false
    t.integer  "flags",               limit: 4,     default: 1
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username",                  limit: 255
    t.string   "first_name",                limit: 255
    t.string   "last_name",                 limit: 255
    t.string   "nickname",                  limit: 255, default: "",       null: false
    t.string   "phone",                     limit: 255
    t.string   "email",                     limit: 255
    t.string   "affiliation",               limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "terms_of_service_accepted"
    t.string   "view_mode",                 limit: 255, default: "normal"
    t.string   "role",                      limit: 255, default: "normal"
    t.boolean  "missing_phone",                         default: false
    t.string   "encrypted_password",        limit: 128, default: "",       null: false
    t.string   "reset_password_token",      limit: 255
    t.datetime "reset_password_sent_at"
    t.string   "cas_login",                 limit: 255
    t.datetime "remember_created_at"
  end

  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "users_requirements", id: false, force: :cascade do |t|
    t.integer "user_id",        limit: 4
    t.integer "requirement_id", limit: 4
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255,   null: false
    t.integer  "item_id",    limit: 4,     null: false
    t.string   "event",      limit: 255,   null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 65535
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
