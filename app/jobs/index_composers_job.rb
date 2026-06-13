class IndexComposersJob < ApplicationJob
  queue_as :default

  def perform(linked_database_id)
    linked_database = LinkedDatabase.find(linked_database_id)
    linked_database.update!(index_status: "indexing", index_error: nil)

    Cursor::ComposerIndexer.new(linked_database).call
  rescue StandardError => e
    linked_database&.update!(index_status: "failed", index_error: e.message)
    raise
  end
end
