# frozen_string_literal: true

namespace :solid_queue do
  desc <<~DESC.squish
    Load db/queue_schema.rb when Solid Queue tables are missing.
    Needed when primary and queue use the same DATABASE_URL: db:prepare marks the DB
    as initialized for the queue role and skips loading queue_schema.rb, so
    deliver_later fails with PG::UndefinedTable (solid_queue_jobs).
  DESC
  task ensure_schema: :environment do
    queue_cfg = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")
    unless queue_cfg
      warn "solid_queue:ensure_schema: no `queue` database config for #{Rails.env} — skipping"
      next
    end

    ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection(queue_cfg) do |conn|
      if conn.table_exists?("solid_queue_jobs")
        next
      end

      Rails.logger.info("solid_queue:ensure_schema: loading db/queue_schema.rb (solid_queue_jobs missing)")
      load Rails.root.join("db/queue_schema.rb")
    end
  end
end
