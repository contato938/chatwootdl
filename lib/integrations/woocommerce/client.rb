require 'net/http'
require 'uri'
require 'json'
require 'openssl'

module Integrations
  module Woocommerce
    class Client
      def initialize(hook)
        @hook = hook
        @settings = hook.settings.with_indifferent_access
        @store_base_url = normalize_url(
          @settings[:store_url] || @settings[:store_base_url] || hook.reference_id
        )
        @consumer_key = @settings[:consumer_key]
        @consumer_secret = resolve_consumer_secret
        @api_version = @settings[:api_version].presence || 'v3'
        @verify_ssl = boolean_setting(@settings.fetch(:verify_ssl, true))
        @request_timeout = (@settings[:request_timeout] || 10).to_i
        @request_timeout = 10 if @request_timeout <= 0
      end

      def test_connection
        response = get('products', per_page: 1, page: 1)
        { success: true, data: response }
      rescue StandardError => e
        { success: false, error: error_message(e) }
      end

      def list_products(page: 1, per_page: 20, search: nil, category: nil)
        current_page = page.to_i.positive? ? page.to_i : 1
        page_size = per_page.to_i.positive? ? per_page.to_i : 20
        page_size = 100 if page_size > 100

        params = {
          page: current_page,
          per_page: page_size,
          _fields: 'id,name,price,regular_price,stock_status,stock_quantity,images,permalink,sku'
        }
        params[:search] = search if search.present?
        params[:category] = category if category.present?

        response = get('products', params)
        {
          products: response,
          pagination: extract_pagination_data(current_page)
        }
      end

      def get_product(product_id)
        get("products/#{product_id}")
      end

      def list_orders_for_customer(email: nil, phone_number: nil, customer_id: nil, page: 1, per_page: 10)
        current_page = page.to_i.positive? ? page.to_i : 1
        page_size = per_page.to_i.positive? ? per_page.to_i : 10
        page_size = 100 if page_size > 100

        params = {
          page: current_page,
          per_page: page_size,
          status: 'any'
        }

        params[:customer] = customer_id || find_customer_id(email: email, phone_number: phone_number)
        params[:search] = email.presence || phone_number if params[:customer].blank?

        response = get('orders', params)

        {
          orders: response,
          pagination: extract_pagination_data(current_page)
        }
      end

      def get_order(order_id)
        get("orders/#{order_id}")
      end

      private

      def boolean_setting(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def ensure_credentials!
        if @store_base_url.blank?
          raise Integrations::Woocommerce::ApiError, 'Store URL is required to connect to WooCommerce'
        end

        return unless @consumer_key.blank? || @consumer_secret.blank?

        raise Integrations::Woocommerce::AuthenticationError,
              'Consumer Key and Consumer Secret are required to connect to WooCommerce'
      end

      def auth_params
        {
          consumer_key: @consumer_key,
          consumer_secret: @consumer_secret
        }
      end

      def resolve_consumer_secret
        stored_secret = @settings[:consumer_secret]
        return stored_secret if stored_secret.present? && stored_secret != '[FILTERED]'

        @hook.access_token.presence || stored_secret
      end

      def get(endpoint, params = {})
        ensure_credentials!
        uri = build_uri(endpoint, params)
        request = Net::HTTP::Get.new(uri)

        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @verify_ssl
        http.open_timeout = @request_timeout
        http.read_timeout = @request_timeout

        response = http.request(request)

        handle_response(response)
      rescue OpenSSL::SSL::SSLError
        raise Integrations::Woocommerce::ApiError, 'SSL verification failed. Please verify your SSL settings.'
      rescue SocketError, Errno::ECONNREFUSED => e
        raise Integrations::Woocommerce::ApiError, "Connection failed: #{e.message}"
      end

      def build_uri(endpoint, params = {})
        base = "#{@store_base_url}/wp-json/wc/#{@api_version}/#{endpoint}"
        uri = URI(base)
        query_params = auth_params.merge(params).compact_blank
        uri.query = URI.encode_www_form(query_params) if query_params.present?
        uri
      end

      def handle_response(response)
        @last_response = response

        case response.code.to_i
        when 200, 201
          JSON.parse(response.body)
        when 401, 403
          raise Integrations::Woocommerce::AuthenticationError, 'Invalid credentials or insufficient permissions'
        when 404
          raise Integrations::Woocommerce::NotFoundError, 'API endpoint not found. Check if WooCommerce is installed and permalinks are enabled'
        else
          raise Integrations::Woocommerce::ApiError, "API returned status #{response.code}: #{response.body}"
        end
      end

      def extract_pagination_data(current_page)
        return {} unless @last_response

        {
          total: @last_response['x-wp-total']&.to_i || 0,
          total_pages: @last_response['x-wp-totalpages']&.to_i || 1,
          current_page: current_page.to_i
        }
      end

      def normalize_url(url)
        return '' if url.blank?

        url.strip.gsub(%r{/+$}, '')
      end

      def error_message(error)
        case error
        when Integrations::Woocommerce::AuthenticationError
          'Authentication failed. Please check your Consumer Key and Consumer Secret.'
        when Integrations::Woocommerce::NotFoundError
          'WooCommerce API not found. Make sure WooCommerce is installed and "Pretty Permalinks" are enabled in WordPress.'
        when Net::OpenTimeout, Net::ReadTimeout
          'Connection timeout. Please check your store URL.'
        else
          "Connection failed: #{error.message}"
        end
      end

      def find_customer_id(email:, phone_number:)
        return if email.blank? && phone_number.blank?

        customer = fetch_customer_by_email(email) || fetch_customer_by_phone(phone_number)
        customer&.dig('id')
      end

      def fetch_customer_by_email(email)
        return if email.blank?

        customers = get('customers', { email: email, per_page: 1 })
        Array.wrap(customers).first
      rescue StandardError
        nil
      end

      def fetch_customer_by_phone(phone_number)
        return if phone_number.blank?

        customers = get('customers', { search: phone_number, per_page: 1 })
        Array.wrap(customers).first
      rescue StandardError
        nil
      end
    end
  end
end
