module Chatwoot
  module PostgresExtensionHelper
    PGVECTOR_EXTENSION = 'vector'.freeze

    module_function

    def pgvector_supported?(connection = ActiveRecord::Base.connection)
      connection.extension_enabled?(PGVECTOR_EXTENSION) ||
        connection.extension_available?(PGVECTOR_EXTENSION)
    rescue ActiveRecord::StatementInvalid, PG::UndefinedTable, PG::UndefinedFunction
      false
    end
  end
end

