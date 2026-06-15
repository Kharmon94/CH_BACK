# frozen_string_literal: true

require "active_support/core_ext/integer/time"
require_relative "../../lib/cursorhelp/paths"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.server_timing = false

  config.action_controller.perform_caching = true
  config.cache_store = :memory_store

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.delivery_method = :test
  config.action_mailer.perform_deliveries = false
  config.active_storage.service = :local
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "127.0.0.1", port: ENV.fetch("PORT", 3847) }

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = false
  config.active_record.query_log_tags_enabled = false
  config.active_job.verbose_enqueue_logs = true
  config.active_job.queue_adapter = :solid_queue

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.action_controller.raise_on_missing_callback_actions = true

  Cursorhelp::Paths.ensure_user_data_dir!
end
