class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :stripe_customer_id
      t.integer :export_count, default: 0, null: false

      t.timestamps
    end
  end
end
