class Phase3Platform < ActiveRecord::Migration[8.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationTeam < ActiveRecord::Base
    self.table_name = "teams"
  end

  class MigrationWorkspace < ActiveRecord::Base
    self.table_name = "workspaces"
  end

  class MigrationLicense < ActiveRecord::Base
    self.table_name = "licenses"
  end

  class MigrationLinkedDatabase < ActiveRecord::Base
    self.table_name = "linked_databases"
  end

  def up
    require "bcrypt"

    change_table :users do |t|
      t.string :encrypted_password, default: "", null: false
      t.integer :role, default: 1, null: false
      t.string :name
      t.string :provider
      t.string :uid
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
    end

    dummy_hash = BCrypt::Password.create("phase3-placeholder", cost: 4).to_s
    MigrationUser.find_each do |user|
      email = user.email.presence || "user#{user.id}@local.cursorhelp"
      MigrationUser.where(id: user.id).update_all(
        encrypted_password: dummy_hash,
        role: 1,
        email: email
      )
    end

    change_column_null :users, :email, false
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    remove_column :users, :export_count

    create_table :teams do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :export_count, default: 0, null: false
      t.timestamps
    end
    add_index :teams, :slug, unique: true

    create_table :team_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.string :role, default: "member", null: false
      t.timestamps
    end
    add_index :team_memberships, [ :user_id, :team_id ], unique: true

    create_table :workspaces do |t|
      t.references :team, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :root_path
      t.timestamps
    end
    add_index :workspaces, [ :team_id, :slug ], unique: true

    create_table :team_invites do |t|
      t.references :team, null: false, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.string :role, default: "member", null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.references :invited_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :team_invites, :token, unique: true

    add_reference :linked_databases, :workspace, foreign_key: true
    add_reference :licenses, :team, foreign_key: true

    now = Time.current
    MigrationUser.find_each do |user|
      team = MigrationTeam.create!(
        name: "My Team",
        slug: "team-#{user.id}-#{SecureRandom.hex(4)}",
        export_count: 0,
        created_at: now,
        updated_at: now
      )
      execute <<~SQL.squish
        INSERT INTO team_memberships (user_id, team_id, role, created_at, updated_at)
        VALUES (#{user.id}, #{team.id}, 'owner', '#{now.to_fs(:db)}', '#{now.to_fs(:db)}')
      SQL
      workspace = MigrationWorkspace.create!(
        team_id: team.id,
        name: "Default",
        slug: "default",
        created_at: now,
        updated_at: now
      )
      if user.id == MigrationUser.minimum(:id)
        MigrationLinkedDatabase.where(workspace_id: nil).update_all(workspace_id: workspace.id)
      end

      license = MigrationLicense.find_by(user_id: user.id)
      if license
        license.update!(team_id: team.id)
      else
        MigrationLicense.create!(
          team_id: team.id,
          tier: "free",
          created_at: now,
          updated_at: now
        )
      end
    end

    if MigrationLinkedDatabase.where(workspace_id: nil).exists?
      default_workspace = MigrationWorkspace.first
      MigrationLinkedDatabase.where(workspace_id: nil).update_all(workspace_id: default_workspace.id) if default_workspace
    end

    remove_reference :licenses, :user, foreign_key: true
    change_column_null :licenses, :team_id, false
    remove_index :licenses, :team_id if index_exists?(:licenses, :team_id)
    add_index :licenses, :team_id, unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
