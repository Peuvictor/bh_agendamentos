# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_08_28_210000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.uuid "service_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer "status", default: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.datetime "expired_at"
    t.datetime "refunded_at"
    t.index ["client_id"], name: "index_appointments_on_client_id"
    t.index ["service_id"], name: "index_appointments_on_service_id"
    t.index ["start_time", "end_time"], name: "index_appointments_on_start_time_and_end_time"
    t.index ["status", "expires_at"], name: "index_appointments_on_status_and_expires_at"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "appointment_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.string "mp_transaction_id"
    t.string "idempotency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "expires_at"
    t.datetime "expired_at"
    t.datetime "refunded_at"
    t.index ["appointment_id"], name: "index_payments_on_appointment_id", unique: true
    t.index ["idempotency_key"], name: "index_payments_on_idempotency_key", unique: true
    t.index ["mp_transaction_id"], name: "index_payments_on_mp_transaction_id", unique: true
    t.index ["status", "expires_at"], name: "index_payments_on_status_and_expires_at"
  end

  create_table "reviews", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "rating"
    t.text "comment"
    t.uuid "appointment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_reviews_on_appointment_id"
  end

  create_table "services", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.decimal "preco", precision: 10, scale: 2
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration"
    t.index ["user_id"], name: "index_services_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "nome", limit: 100, null: false
    t.integer "role", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "telefone"
    t.text "bio"
    t.string "endereco"
    t.string "bairro"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhook_deliveries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "provider", limit: 50, default: "mercado_pago", null: false
    t.string "gateway_request_id", limit: 255
    t.string "rails_request_id", limit: 255
    t.string "event_type", limit: 100
    t.string "event_action", limit: 100
    t.string "resource_id", limit: 255
    t.uuid "payment_id"
    t.integer "status", default: 0, null: false
    t.string "service_result", limit: 100
    t.string "remote_status", limit: 100
    t.string "failure_code", limit: 100
    t.string "error_class", limit: 255
    t.integer "response_status"
    t.integer "duration_ms"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gateway_request_id"], name: "index_webhook_deliveries_on_gateway_request_id"
    t.index ["payment_id"], name: "index_webhook_deliveries_on_payment_id"
    t.index ["resource_id"], name: "index_webhook_deliveries_on_resource_id"
    t.index ["status", "created_at"], name: "index_webhook_deliveries_on_status_and_created_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "appointments", "services"
  add_foreign_key "appointments", "users", column: "client_id"
  add_foreign_key "payments", "appointments"
  add_foreign_key "reviews", "appointments"
  add_foreign_key "services", "users"
  add_foreign_key "webhook_deliveries", "payments", on_delete: :nullify
end
