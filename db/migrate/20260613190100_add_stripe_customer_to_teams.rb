class AddStripeCustomerToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :stripe_customer_id, :string
    if column_exists?(:users, :stripe_customer_id)
      execute <<~SQL.squish
        UPDATE teams
        SET stripe_customer_id = (
          SELECT users.stripe_customer_id FROM users
          INNER JOIN team_memberships ON team_memberships.user_id = users.id
          WHERE team_memberships.team_id = teams.id
            AND team_memberships.role = 'owner'
            AND users.stripe_customer_id IS NOT NULL
          LIMIT 1
        )
      SQL
      remove_column :users, :stripe_customer_id, :string
    end
  end
end
