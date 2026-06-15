# frozen_string_literal: true

namespace :solid_cache do
  desc <<~DESC.squish
    Load db/cache_schema.rb when Solid Cache tables are missing.
    Needed when primary and cache use the same DATABASE_URL: db:prepare marks the DB
    as initialized for the cache role and skips loading cache_schema.rb, so
    Rails.cache.write fails with ArgumentError (No unique index found for key_hash).
  DESC
  task ensure_schema: :environment do
    cache_cfg = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "cache")
    unless cache_cfg
      warn "solid_cache:ensure_schema: no `cache` database config for #{Rails.env} — skipping"
      next
    end

    ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection(cache_cfg) do |conn|
      if conn.table_exists?("solid_cache_entries") &&
         conn.indexes("solid_cache_entries").any? { |i| i.unique && i.columns == [ "key_hash" ] }
        next
      end

      Rails.logger.info("solid_cache:ensure_schema: loading db/cache_schema.rb (solid_cache_entries missing or incomplete)")
      load Rails.root.join("db/cache_schema.rb")
    end
  end
end
