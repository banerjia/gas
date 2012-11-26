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

ActiveRecord::Schema.define(:version => 20121123151806) do

  create_table "audit_journals", :primary_key => "audit_id", :force => true do |t|
    t.string    "title",      :limit => 50
    t.string    "body",       :limit => 1024
    t.string    "tags",       :limit => 1024
    t.timestamp "created_at",                 :null => false
    t.timestamp "updated_at",                 :null => false
  end

  create_table "audits", :force => true do |t|
    t.integer   "store_id",         :limit => 8,                  :null => false
    t.integer   "points_available", :limit => 2,  :default => 25, :null => false
    t.integer   "score",            :limit => 2,  :default => 0,  :null => false
    t.integer   "status",           :limit => 1,  :default => 0,  :null => false
    t.string    "auditor_name",     :limit => 50,                 :null => false
    t.string    "store_rep",        :limit => 50
    t.timestamp "created_at",                                     :null => false
    t.timestamp "updated_at",                                     :null => false
  end

  add_index "audits", ["store_id", "status", "created_at", "id", "score"], :name => "Store_Audit_History"

  create_table "companies", :force => true do |t|
    t.string    "name",         :limit => 150,                :null => false
    t.integer   "stores_count", :limit => 3,   :default => 0, :null => false
    t.integer   "active",       :limit => 1,   :default => 1, :null => false
    t.timestamp "created_at",                                 :null => false
    t.timestamp "updated_at",                                 :null => false
  end

  add_index "companies", ["id"], :name => "CompanyID_UNIQUE", :unique => true

  create_table "metrics", :force => true do |t|
    t.string    "title",                                          :null => false
    t.string    "description"
    t.integer   "points",           :limit => 2,  :default => 1,  :null => false
    t.datetime  "start_date"
    t.datetime  "end_date"
    t.integer   "display_order",    :limit => 2
    t.string    "category",         :limit => 20
    t.integer   "quantifier",       :limit => 2,  :default => -1, :null => false
    t.integer   "allows_free_form", :limit => 1,  :default => 0,  :null => false
    t.integer   "trigger_alert",    :limit => 1,  :default => 0,  :null => false
    t.integer   "include",          :limit => 1,  :default => 1,  :null => false
    t.integer   "reverse_options",  :limit => 1,  :default => 0,  :null => false
    t.timestamp "created_at",                                     :null => false
    t.timestamp "updated_at",                                     :null => false
  end

  create_table "orders", :force => true do |t|
    t.string   "invoice_number", :limit => 20
    t.datetime "delivery_date"
    t.boolean  "fulfilled",                                                   :default => false, :null => false
    t.string   "route_number",   :limit => 5
    t.integer  "store_id",       :limit => 8,                                                    :null => false
    t.decimal  "invoice_amount",               :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.datetime "created_at",                                                                     :null => false
    t.datetime "updated_at",                                                                     :null => false
  end

  add_index "orders", ["fulfilled", "id"], :name => "index_orders_on_fulfilled_and_id"
  add_index "orders", ["store_id"], :name => "index_orders_on_store_id"

  create_table "people", :force => true do |t|
    t.string   "name",                            :limit => 100
    t.string   "email",                                                             :null => false
    t.string   "crypted_password"
    t.string   "salt"
    t.boolean  "is_admin",                                       :default => false, :null => false
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
  end

  add_index "people", ["remember_me_token"], :name => "index_people_on_remember_me_token"
  add_index "people", ["reset_password_token"], :name => "index_people_on_reset_password_token"

  create_table "product_categories", :force => true do |t|
    t.string  "name",                 :limit => 50,                    :null => false
    t.integer "volume_unit_id",       :limit => 2,  :default => 1
    t.boolean "limited_availability",               :default => false, :null => false
  end

  create_table "product_orders", :id => false, :force => true do |t|
    t.integer "order_id",                                   :null => false
    t.integer "product_id",                                 :null => false
    t.integer "quantity",       :limit => 2, :default => 1, :null => false
    t.integer "volume_unit_id", :limit => 2, :default => 1, :null => false
  end

  add_index "product_orders", ["order_id", "product_id"], :name => "index_product_orders_on_order_id_and_product_id", :unique => true
  add_index "product_orders", ["product_id"], :name => "index_product_orders_on_product_id"
  add_index "product_orders", ["volume_unit_id", "quantity"], :name => "index_product_orders_on_volume_unit_id_and_quantity"

  create_table "products", :force => true do |t|
    t.string   "name",                :limit => 250,                   :null => false
    t.string   "code",                :limit => 10,                    :null => false
    t.integer  "product_category_id",                :default => 1,    :null => false
    t.string   "available_from",      :limit => 10
    t.string   "available_till",      :limit => 10
    t.boolean  "active",                             :default => true, :null => false
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
  end

  add_index "products", ["active", "code"], :name => "index_products_on_active_and_code"
  add_index "products", ["active", "product_category_id"], :name => "index_products_on_active_and_product_category_id"
  add_index "products", ["code", "name"], :name => "index_products_on_code_and_name"

  create_table "states", :id => false, :force => true do |t|
    t.string  "country",          :limit => 20,  :default => "US", :null => false
    t.string  "state_name",       :limit => 150,                   :null => false
    t.string  "state_code",       :limit => 10,                    :null => false
    t.integer "number_of_stores", :limit => 3,   :default => 0,    :null => false
  end

  add_index "states", ["country", "state_code"], :name => "idx_composite_primary", :unique => true

  create_table "store_metrics", :id => false, :force => true do |t|
    t.integer   "audit_id",    :limit => 8,                :null => false
    t.integer   "metric_id",                               :null => false
    t.integer   "point_value",                             :null => false
    t.integer   "include",     :limit => 1, :default => 1, :null => false
    t.datetime  "resolved_at"
    t.timestamp "created_at",                              :null => false
    t.timestamp "updated_at",                              :null => false
  end

  add_index "store_metrics", ["audit_id"], :name => "AuditSessionID"
  add_index "store_metrics", ["metric_id", "audit_id"], :name => "MetricsIDAuditSessionID", :unique => true
  add_index "store_metrics", ["metric_id"], :name => "MetricsID"
  add_index "store_metrics", ["point_value"], :name => "PointValue"

  create_table "stores", :force => true do |t|
    t.integer   "company_id",     :limit => 3,                                                   :null => false
    t.string    "name",           :limit => 150
    t.string    "street_address", :limit => 200
    t.string    "suite",          :limit => 100
    t.string    "city",           :limit => 150
    t.string    "state_code",     :limit => 10,                                :default => "OH", :null => false
    t.string    "zip",            :limit => 10
    t.string    "country",        :limit => 3,                                 :default => "US", :null => false
    t.string    "store_number",   :limit => 10
    t.string    "phone",          :limit => 15
    t.integer   "orders_count",   :limit => 3,                                 :default => 0,    :null => false
    t.datetime  "created_at"
    t.timestamp "updated_at",                                                                    :null => false
    t.decimal   "latitude",                      :precision => 8, :scale => 6
    t.decimal   "longitude",                     :precision => 8, :scale => 6
  end

  add_index "stores", ["company_id", "country", "state_code"], :name => "Stores_by_company_and_location"
  add_index "stores", ["company_id"], :name => "CompanyID"

  create_table "volume_units", :force => true do |t|
    t.string   "name",       :limit => 20, :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "zip_codes", :id => false, :force => true do |t|
    t.string  "country",    :limit => 2,                                 :default => "US", :null => false
    t.string  "zip",        :limit => 10,                                                  :null => false
    t.string  "city",       :limit => 150,                                                 :null => false
    t.string  "state_code", :limit => 5,                                                   :null => false
    t.decimal "lat",                       :precision => 8, :scale => 6,                   :null => false
    t.decimal "lng",                       :precision => 8, :scale => 6,                   :null => false
    t.integer "loc",        :limit => nil,                                                 :null => false
  end

end
