class CreateCaptainTables < ActiveRecord::Migration[7.0]
  def up
    create_assistants
    create_documents

    return unless setup_vector_extension

    create_assistant_responses
    create_old_tables
  end

  def down
    drop_table :captain_assistant_responses if table_exists?(:captain_assistant_responses)
    drop_table :captain_documents if table_exists?(:captain_documents)
    drop_table :captain_assistants if table_exists?(:captain_assistants)
    drop_table :article_embeddings if table_exists?(:article_embeddings)

    # We are not disabling the extension here because it might be
    # used by other tables which are not part of this migration.
  end

  private

  def setup_vector_extension
    return true if extension_enabled?('vector')
    unless vector_extension_available?
      log_vector_extension_warning
      return false
    end

    enable_extension 'vector'
    true
  rescue ActiveRecord::StatementInvalid => e
    log_vector_extension_warning(e.message)
    false
  end

  def create_assistants
    create_table :captain_assistants do |t|
      t.string :name, null: false
      t.bigint :account_id, null: false
      t.string :description

      t.timestamps
    end

    add_index :captain_assistants, :account_id
    add_index :captain_assistants, [:account_id, :name], unique: true
  end

  def create_documents
    create_table :captain_documents do |t|
      t.string :name, null: false
      t.string :external_link, null: false
      t.text :content
      t.bigint :assistant_id, null: false
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_documents, :account_id
    add_index :captain_documents, :assistant_id
    add_index :captain_documents, [:assistant_id, :external_link], unique: true
  end

  def create_assistant_responses
    create_table :captain_assistant_responses do |t|
      t.string :question, null: false
      t.text :answer, null: false
      t.vector :embedding, limit: 1536
      t.bigint :assistant_id, null: false
      t.bigint :document_id
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_assistant_responses, :account_id
    add_index :captain_assistant_responses, :assistant_id
    add_index :captain_assistant_responses, :document_id
    add_index :captain_assistant_responses, :embedding, using: :ivfflat, name: 'vector_idx_knowledge_entries_embedding', opclass: :vector_l2_ops
  end

  def create_old_tables
    create_table :article_embeddings, if_not_exists: true do |t|
      t.bigint :article_id, null: false
      t.text :term, null: false
      t.vector :embedding, limit: 1536
      t.timestamps
    end
    add_index :article_embeddings, :embedding, if_not_exists: true, using: :ivfflat, opclass: :vector_l2_ops
  end

  def vector_extension_available?
    helper = defined?(Chatwoot::PostgresExtensionHelper) ? Chatwoot::PostgresExtensionHelper : nil
    if helper
      helper.pgvector_supported?(connection)
    else
      connection.extension_available?('vector')
    end
  rescue ActiveRecord::StatementInvalid
    false
  end

  def log_vector_extension_warning(details = nil)
    message = "Extensão 'vector' indisponível; pulando tabelas de embeddings."
    message = "#{message} #{details}" if details

    if defined?(Rails) && Rails.logger
      Rails.logger.warn(message)
    else
      puts(message)
    end
  end
end
