module Integrations
  module Woocommerce
    module Exceptions
      class Error < StandardError; end
      class ApiError < Error; end
      class AuthenticationError < Error; end
      class NotFoundError < Error; end
    end

    # Backward compatibility aliases
    Error = Exceptions::Error
    ApiError = Exceptions::ApiError
    AuthenticationError = Exceptions::AuthenticationError
    NotFoundError = Exceptions::NotFoundError
  end
end
