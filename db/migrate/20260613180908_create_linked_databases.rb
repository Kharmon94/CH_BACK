class CreateLinkedDatabases < ActiveRecord::Migration[8.0]
  def change
    create_table :linked_databases do |t|
      t.string :path
      t.integer :composer_count, default: 0, null: false
      t.datetime :last_indexed_at
      t.string :index_status, default: "idle", null: false
      t.text :index_error

      t.timestamps
    end
    add_index :linked_databases, :path, unique: true
  end
end
