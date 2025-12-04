module Chatwoot
  module PgVectorExtensionGuard
    PGVECTOR_EXTENSION = 'vector'.freeze

    def enable_extension(name, schema = nil)
      return super unless name.to_s == PGVECTOR_EXTENSION

      super
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn(
        "Extensão '#{PGVECTOR_EXTENSION}' indisponível, seguindo sem pgvector: #{e.message}"
      )
      false
    end
  end
end

postgresql_schema_statements = ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements
postgresql_schema_statements.prepend(Chatwoot::PgVectorExtensionGuard)

