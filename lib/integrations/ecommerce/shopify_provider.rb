module Integrations
  module Ecommerce
    class ShopifyProvider < BaseProvider
      def list_products(page: 1, per_page: 20, search: nil)
        setup_shopify_context
        client = shopify_client

        query_params = {
          limit: [per_page, 250].min,
          fields: 'id,title,variants,image'
        }
        query_params[:title] = search if search.present?

        response = client.get(path: 'products.json', query: query_params)
        products = response.body['products'] || []

        # Transform Shopify products to normalized format
        normalized_products = products.map do |product|
          variant = product['variants']&.first || {}
          {
            id: product['id'],
            name: product['title'],
            sku: variant['sku'],
            price: variant['price'],
            thumbnail_url: product['image']&.dig('src'),
            stock_status: variant['inventory_quantity'].to_i.positive? ? 'in_stock' : 'out_of_stock',
            product_url: "https://#{@hook.reference_id}/admin/products/#{product['id']}"
          }
        end

        {
          products: normalized_products,
          pagination: { total: products.size, current_page: page },
          provider: 'shopify'
        }
      end

      def get_product(product_id)
        setup_shopify_context
        client = shopify_client

        response = client.get(path: "products/#{product_id}.json")
        product = response.body['product']

        variant = product['variants']&.first || {}
        normalize_product({
          id: product['id'],
          name: product['title'],
          sku: variant['sku'],
          price: variant['price'],
          images: [{ 'src' => product['image']&.dig('src') }],
          stock_status: variant['inventory_quantity'].to_i.positive? ? 'instock' : 'outofstock',
          permalink: "https://#{@hook.reference_id}/admin/products/#{product['id']}"
        }, 'shopify')
      end

      def list_orders(contact:)
        setup_shopify_context
        customers = fetch_customers(contact)
        return { orders: [], pagination: {}, provider: 'shopify' } if customers.empty?

        orders = fetch_orders(customers.first['id'])
        {
          orders: orders.map { |order| normalize_order(transform_order(order), 'shopify') },
          pagination: { total: orders.size, current_page: 1 },
          provider: 'shopify'
        }
      end

      private

      def setup_shopify_context
        return if ShopifyAPI::Context.api_key.present?

        client_id = GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
        client_secret = GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)

        ShopifyAPI::Context.setup(
          api_key: client_id,
          api_secret_key: client_secret,
          api_version: '2025-01',
          scope: 'read_products,read_customers,read_orders',
          is_embedded: true,
          is_private: false
        )
      end

      def shopify_session
        ShopifyAPI::Auth::Session.new(shop: @hook.reference_id, access_token: @hook.access_token)
      end

      def shopify_client
        @shopify_client ||= ShopifyAPI::Clients::Rest::Admin.new(session: shopify_session)
      end

      def fetch_customers(contact)
        query = []
        query << "email:#{contact.email}" if contact&.email.present?
        query << "phone:#{contact.phone_number}" if contact&.phone_number.present?

        return [] if query.empty?

        shopify_client.get(
          path: 'customers/search.json',
          query: {
            query: query.join(' OR '),
            fields: 'id,email,phone'
          }
        ).body['customers'] || []
      end

      def fetch_orders(customer_id)
        shopify_client.get(
          path: 'orders.json',
          query: {
            customer_id: customer_id,
            status: 'any',
            fields: 'id,email,created_at,total_price,currency,fulfillment_status,financial_status'
          }
        ).body['orders'] || []
      end

      def transform_order(order)
        order.merge('order_url' => "https://#{@hook.reference_id}/admin/orders/#{order['id']}")
      end
    end
  end
end
