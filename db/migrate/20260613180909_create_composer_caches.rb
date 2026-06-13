class CreateComposerCaches < ActiveRecord::Migration[8.0]
  def change
    create_table :composer_caches do |t|
      t.references :linked_database, null: false, foreign_key: true
      t.string :composer_id, null: false
      t.string :name
      t.string :status
      t.string :mode
      t.integer :message_count, default: 0
      t.bigint :created_at_ms
      t.bigint :updated_at_ms

      t.timestamps
    end

    add_index :composer_caches, [ :linked_database_id, :composer_id ], unique: true
    add_index :composer_caches, :name
    add_index :composer_caches, :updated_at_ms
  end
end
