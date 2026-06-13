class CreateLicenses < ActiveRecord::Migration[8.0]
  def change
    create_table :licenses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tier, default: "free", null: false
      t.string :stripe_subscription_id
      t.string :status
      t.datetime :expires_at

      t.timestamps
    end
  end
end
