module Integrations
  module Ecommerce
    class WoocommerceProvider < BaseProvider
      def list_products(page: 1, per_page: 20, search: nil)
        client = Integrations::Woocommerce::Client.new(@hook)
        result = client.list_products(page: page, per_page: per_page, search: search)

        {
          products: result[:products].map { |p| normalize_product(p, 'woocommerce') },
          pagination: result[:pagination],
          provider: 'woocommerce'
        }
      end

      def get_product(product_id)
        client = Integrations::Woocommerce::Client.new(@hook)
        product = client.get_product(product_id)
        normalize_product(product, 'woocommerce')
      end

      def list_orders(contact:)
        client = Integrations::Woocommerce::Client.new(@hook)
        response = client.list_orders_for_customer(
          email: contact&.email,
          phone_number: contact&.phone_number,
          customer_id: contact&.additional_attributes&.dig('woocommerce_customer_id')
        )

        {
          orders: Array.wrap(response[:orders]).map { |order| normalize_order(transform_order(order), 'woocommerce') },
          pagination: response[:pagination],
          provider: 'woocommerce'
        }
      end

      private

      def transform_order(order)
        order_url = nil
        base_url = store_url
        order_url = "#{base_url}/wp-admin/post.php?post=#{order['id']}&action=edit" if base_url.present?

        order.merge(
          'order_url' => order_url,
          'order_number' => order['number'] || order['id']
        )
      end
    end
  end
end
