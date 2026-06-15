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

ActiveRecord::Schema[8.0].define(version: 2026_06_14_100000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
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

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "blog_posts", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "excerpt"
    t.text "body"
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.string "meta_title"
    t.string "meta_description"
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_blog_posts_on_author_id"
    t.index ["published_at"], name: "index_blog_posts_on_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["status"], name: "index_blog_posts_on_status"
  end

  create_table "composer_caches", force: :cascade do |t|
    t.integer "linked_database_id", null: false
    t.string "composer_id", null: false
    t.string "name"
    t.string "status"
    t.string "mode"
    t.integer "message_count", default: 0
    t.bigint "created_at_ms"
    t.bigint "updated_at_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linked_database_id", "composer_id"], name: "index_composer_caches_on_linked_database_id_and_composer_id", unique: true
    t.index ["linked_database_id"], name: "index_composer_caches_on_linked_database_id"
    t.index ["name"], name: "index_composer_caches_on_name"
    t.index ["updated_at_ms"], name: "index_composer_caches_on_updated_at_ms"
  end

  create_table "export_records", force: :cascade do |t|
    t.integer "linked_database_id", null: false
    t.string "composer_id"
    t.string "composer_name"
    t.string "format"
    t.string "status", default: "queued", null: false
    t.integer "progress_pct", default: 0, null: false
    t.string "phase"
    t.text "error_message"
    t.string "file_path"
    t.integer "session_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linked_database_id"], name: "index_export_records_on_linked_database_id"
  end

  create_table "licenses", force: :cascade do |t|
    t.string "tier", default: "free", null: false
    t.string "stripe_subscription_id"
    t.string "status"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_id", null: false
    t.index ["team_id"], name: "index_licenses_on_team_id", unique: true
  end

  create_table "linked_databases", force: :cascade do |t|
    t.string "path"
    t.integer "composer_count", default: 0, null: false
    t.datetime "last_indexed_at"
    t.string "index_status", default: "idle", null: false
    t.text "index_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "workspace_id"
    t.index ["path"], name: "index_linked_databases_on_path", unique: true
    t.index ["workspace_id"], name: "index_linked_databases_on_workspace_id"
  end

  create_table "team_invites", force: :cascade do |t|
    t.integer "team_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.string "role", default: "member", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.integer "invited_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_team_invites_on_invited_by_id"
    t.index ["team_id"], name: "index_team_invites_on_team_id"
    t.index ["token"], name: "index_team_invites_on_token", unique: true
  end

  create_table "team_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "team_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id", "team_id"], name: "index_team_memberships_on_user_id_and_team_id", unique: true
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "export_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_customer_id"
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "role", default: 1, null: false
    t.string "name"
    t.string "provider"
    t.string "uid"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "stripe_customer_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.integer "team_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "root_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "slug"], name: "index_workspaces_on_team_id_and_slug", unique: true
    t.index ["team_id"], name: "index_workspaces_on_team_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blog_posts", "users", column: "author_id"
  add_foreign_key "composer_caches", "linked_databases"
  add_foreign_key "export_records", "linked_databases"
  add_foreign_key "licenses", "teams"
  add_foreign_key "linked_databases", "workspaces"
  add_foreign_key "team_invites", "teams"
  add_foreign_key "team_invites", "users", column: "invited_by_id"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "workspaces", "teams"
end
