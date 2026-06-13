class CreateExportRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :export_records do |t|
      t.references :linked_database, null: false, foreign_key: true
      t.string :composer_id
      t.string :composer_name
      t.string :format
      t.string :status, default: "queued", null: false
      t.integer :progress_pct, default: 0, null: false
      t.string :phase
      t.text :error_message
      t.string :file_path
      t.integer :session_count

      t.timestamps
    end
  end
end
