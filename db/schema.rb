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

ActiveRecord::Schema.define(version: 20150626035746) do

  create_table "audit_journals", primary_key: "audit_id", force: true do |t|
    t.string    "title",      limit: 50
    t.string    "body",       limit: 1024
    t.string    "tags",       limit: 1024
    t.timestamp "created_at",              null: false
    t.timestamp "updated_at",              null: false
  end

  create_table "audit_metric_responses", id: false, force: true do |t|
    t.integer "metric_option_id", limit: 3,    null: false
    t.integer "audit_id",         limit: 8,    null: false
    t.integer "metric_id",        limit: 3,    null: false
    t.boolean "selected"
    t.string  "entry_value",      limit: 1024, null: false
  end

  create_table "audit_metrics", id: false, force: true do |t|
    t.integer "audit_id",   limit: 8,                   null: false
    t.integer "metric_id",  limit: 3,                   null: false
    t.string  "score_type", limit: 15, default: "base", null: false
    t.integer "loss",       limit: 2,  default: 0,      null: false
    t.integer "bonus",      limit: 2,  default: 0,      null: false
    t.integer "base",       limit: 2,  default: 0,      null: false
    t.boolean "resolved",              default: false,  null: false
  end

  add_index "audit_metrics", ["audit_id", "resolved"], name: "index_audit_metrics_on_audit_id_and_needs_resolution", using: :btree

  create_table "audits", force: true do |t|
    t.string    "auditor_name",          limit: 30
    t.integer   "store_id",              limit: 8,                  null: false
    t.integer   "base",                  limit: 2,  default: 0,     null: false
    t.integer   "loss",                  limit: 2,  default: 0,     null: false
    t.integer   "bonus",                 limit: 2,  default: 0,     null: false
    t.boolean   "has_unresolved_issues",            default: false
    t.timestamp "created_at",                                       null: false
    t.timestamp "updated_at",                                       null: false
  end

  add_index "audits", ["store_id", "created_at", "id"], name: "Store_Audit_History", using: :btree
  add_index "audits", ["store_id", "has_unresolved_issues"], name: "index_audits_on_store_id_and_has_unresolved_issues", using: :btree

  create_table "comments", id: false, force: true do |t|
    t.integer  "commentable_id",   limit: 8,  null: false
    t.string   "commentable_type", limit: 50
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree

  create_table "companies", force: true do |t|
    t.string    "name",          limit: 150,                null: false
    t.string    "url_part"
    t.integer   "stores_count",  limit: 3,   default: 0,    null: false
    t.integer   "regions_count", limit: 2,   default: 0,    null: false
    t.boolean   "active",                    default: true, null: false
    t.timestamp "created_at",                               null: false
    t.timestamp "updated_at",                               null: false
  end

  add_index "companies", ["active", "url_part"], name: "index_companies_on_active_and_url_part", using: :btree
  add_index "companies", ["id"], name: "CompanyID_UNIQUE", unique: true, using: :btree
  add_index "companies", ["url_part"], name: "index_companies_on_url_part", unique: true, using: :btree

  create_table "images", id: false, force: true do |t|
    t.integer  "imageable_id",   limit: 8,                    null: false
    t.string   "imageable_type"
    t.string   "content_type",   limit: 150
    t.string   "content_url",    limit: 1024
    t.boolean  "processed",                   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "images", ["imageable_id", "imageable_type"], name: "index_images_on_imageable_id_and_imageable_type", using: :btree
  add_index "images", ["processed"], name: "index_images_on_processed", using: :btree

  create_table "metric_options", force: true do |t|
    t.integer "metric_id",     limit: 3,                                         null: false
    t.string  "label"
    t.integer "points",        limit: 2,                         default: 0,     null: false
    t.boolean "isBonus",                                         default: false, null: false
    t.integer "display_order", limit: 2,                         default: 0,     null: false
    t.decimal "weight",                  precision: 4, scale: 1, default: 100.0, null: false
  end

  create_table "metrics", force: true do |t|
    t.string    "title",                                             null: false
    t.string    "description"
    t.datetime  "start_date"
    t.datetime  "end_date"
    t.integer   "display_order",         limit: 1,  default: 1,      null: false
    t.string    "score_type",            limit: 15, default: "base", null: false
    t.boolean   "free_form_response",               default: false
    t.boolean   "apply_points_per_item",            default: false
    t.string    "response_type"
    t.boolean   "track_resolution",                 default: true,   null: false
    t.integer   "metric_options_count",  limit: 1,  default: 0,      null: false
    t.timestamp "created_at",                                        null: false
    t.timestamp "updated_at",                                        null: false
  end

  create_table "new_sort_order", id: false, force: true do |t|
    t.string  "product_code", limit: 20, null: false
    t.integer "sort_order",              null: false
  end

  create_table "orders", force: true do |t|
    t.integer  "store_id",        limit: 8,                  null: false
    t.string   "invoice_number",  limit: 20
    t.integer  "delivery_dow",    limit: 2
    t.integer  "route_id",        limit: 2
    t.boolean  "email_sent",                 default: false, null: false
    t.datetime "email_sent_date"
    t.boolean  "available_in_s3",            default: false, null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "orders", ["email_sent", "id"], name: "index_orders_on_fulfilled_and_id", using: :btree
  add_index "orders", ["store_id"], name: "index_orders_on_store_id", using: :btree

  create_table "people", force: true do |t|
    t.string   "name",                            limit: 100
    t.string   "email",                                                       null: false
    t.string   "crypted_password"
    t.string   "salt"
    t.boolean  "is_admin",                                    default: false, null: false
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
  end

  add_index "people", ["remember_me_token"], name: "index_people_on_remember_me_token", using: :btree
  add_index "people", ["reset_password_token"], name: "index_people_on_reset_password_token", using: :btree

  create_table "product_categories", force: true do |t|
    t.string  "name",                 limit: 50,                 null: false
    t.integer "volume_unit_id",       limit: 2,  default: 1
    t.boolean "limited_availability",            default: false, null: false
    t.integer "display_order",        limit: 2,  default: 65535, null: false
  end

  create_table "product_orders", id: false, force: true do |t|
    t.integer "order_id",                             null: false
    t.integer "product_id",                           null: false
    t.integer "quantity",       limit: 2, default: 1, null: false
    t.integer "volume_unit_id", limit: 2, default: 1, null: false
  end

  add_index "product_orders", ["order_id", "product_id"], name: "index_product_orders_on_order_id_and_product_id", unique: true, using: :btree
  add_index "product_orders", ["product_id"], name: "index_product_orders_on_product_id", using: :btree
  add_index "product_orders", ["volume_unit_id", "quantity"], name: "index_product_orders_on_volume_unit_id_and_quantity", using: :btree

  create_table "products", force: true do |t|
    t.string   "name",                       limit: 250,                null: false
    t.string   "code",                       limit: 10,                 null: false
    t.integer  "product_category_id",                    default: 1,    null: false
    t.datetime "from"
    t.datetime "till"
    t.integer  "sort_order_for_order_sheet", limit: 2,   default: 0,    null: false
    t.boolean  "active",                                 default: true, null: false
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
  end

  add_index "products", ["active", "code"], name: "index_products_on_active_and_code", using: :btree
  add_index "products", ["active", "product_category_id"], name: "index_products_on_active_and_product_category_id", using: :btree
  add_index "products", ["code", "name"], name: "index_products_on_code_and_name", using: :btree

  create_table "regions", force: true do |t|
    t.string  "name",         limit: 50,             null: false
    t.integer "company_id",   limit: 3,              null: false
    t.integer "stores_count", limit: 2,  default: 0, null: false
  end

  add_index "regions", ["company_id", "stores_count"], name: "index_regions_on_company_id_and_stores_count", using: :btree

  create_table "routes", force: true do |t|
    t.string  "name",         limit: 50,             null: false
    t.integer "stores_count", limit: 2,  default: 0, null: false
    t.integer "active",       limit: 1,  default: 1, null: false
  end

  create_table "states", id: false, force: true do |t|
    t.string  "country",          limit: 20,  default: "US", null: false
    t.string  "state_name",       limit: 150,                null: false
    t.string  "state_code",       limit: 10,                 null: false
    t.integer "number_of_stores", limit: 3,   default: 0,    null: false
  end

  add_index "states", ["country", "state_code"], name: "idx_composite_primary", unique: true, using: :btree

  create_table "store_contacts", id: false, force: true do |t|
    t.integer  "store_id",   limit: 8,   null: false
    t.string   "name",       limit: 100
    t.string   "title",      limit: 150
    t.string   "phone",      limit: 20
    t.string   "email"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "store_contacts", ["store_id"], name: "index_store_contacts_on_store_id", using: :btree

  create_table "stores", force: true do |t|
    t.string    "url_id"
    t.integer   "company_id",     limit: 3,                  null: false
    t.integer   "region_id",      limit: 3
    t.string    "name",           limit: 150
    t.string    "locality",       limit: 100
    t.string    "street_address", limit: 200
    t.string    "suite",          limit: 100
    t.string    "city",           limit: 150
    t.string    "county"
    t.string    "state_code",                                null: false
    t.string    "zip",            limit: 10
    t.string    "country",        limit: 3,   default: "US", null: false
    t.string    "store_number",   limit: 10
    t.string    "phone",          limit: 15
    t.integer   "orders_count",   limit: 3,   default: 0,    null: false
    t.integer   "audits_count",   limit: 2,   default: 0,    null: false
    t.float     "latitude",       limit: 24
    t.float     "longitude",      limit: 24
    t.boolean   "active",                     default: true, null: false
    t.datetime  "created_at"
    t.timestamp "updated_at",                                null: false
  end

  add_index "stores", ["active", "url_id"], name: "index_stores_on_active_and_url_id", using: :btree
  add_index "stores", ["active"], name: "index_stores_on_active", using: :btree
  add_index "stores", ["company_id", "country", "state_code"], name: "Stores_by_company_and_location", using: :btree
  add_index "stores", ["company_id"], name: "CompanyID", using: :btree
  add_index "stores", ["url_id"], name: "index_stores_on_url_id", unique: true, using: :btree

  create_table "volume_units", force: true do |t|
    t.string   "name",              limit: 20,                                        null: false
    t.string   "unit_code",         limit: 15,                         default: "oz", null: false
    t.decimal  "sleeve_conversion",            precision: 5, scale: 3, default: 0.0,  null: false
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
  end

end
