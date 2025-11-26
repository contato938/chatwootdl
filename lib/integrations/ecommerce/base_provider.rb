module Integrations
  module Ecommerce
    class BaseProvider
      def initialize(hook)
        @hook = hook
      end

      def list_products(page: 1, per_page: 20, search: nil)
        raise NotImplementedError, 'Subclasses must implement list_products'
      end

      def get_product(product_id)
        raise NotImplementedError, 'Subclasses must implement get_product'
      end

      def list_orders(contact:)
        raise NotImplementedError, 'Subclasses must implement list_orders'
      end

      private

      def normalize_product(raw_product, provider)
        {
          id: raw_product[:id] || raw_product['id'],
          provider: provider,
          name: raw_product[:name] || raw_product['name'] || raw_product[:title] || raw_product['title'],
          sku: raw_product[:sku] || raw_product['sku'],
          price: extract_price(raw_product),
          thumbnail_url: extract_thumbnail(raw_product),
          stock_status: extract_stock_status(raw_product),
          product_url: raw_product[:permalink] || raw_product['permalink'] || raw_product[:admin_url] || raw_product['admin_url']
        }
      end

      def extract_price(product)
        product[:price] || product['price'] || product[:regular_price] || product['regular_price'] || '0'
      end

      def extract_thumbnail(product)
        images = product[:images] || product['images'] || product[:image] || product['image']
        return nil if images.blank?

        if images.is_a?(Array)
          images.first&.dig('src') || images.first&.dig(:src)
        elsif images.is_a?(Hash)
          images['src'] || images[:src]
        else
          images
        end
      end

      def extract_stock_status(product)
        status = product[:stock_status] || product['stock_status']
        return 'unknown' if status.blank?

        status == 'instock' || status == 'in_stock' ? 'in_stock' : 'out_of_stock'
      end

      def normalize_order(raw_order, provider)
        {
          id: raw_order[:id] || raw_order['id'],
          order_number: raw_order[:order_number] || raw_order['order_number'] || raw_order[:id] || raw_order['id'],
          created_at: raw_order[:created_at] || raw_order['created_at'] || raw_order[:date_created] || raw_order['date_created'],
          total_price: raw_order[:total_price] || raw_order['total_price'] || raw_order[:total] || raw_order['total'],
          currency: raw_order[:currency] || raw_order['currency'],
          financial_status: raw_order[:financial_status] || raw_order['financial_status'],
          fulfillment_status: raw_order[:fulfillment_status] || raw_order['fulfillment_status'],
          status: raw_order[:status] || raw_order['status'],
          order_url: raw_order[:order_url] || raw_order['order_url'] || raw_order[:admin_url] || raw_order['admin_url'],
          provider: provider
        }
      end

      def store_url
        settings = @hook.settings.with_indifferent_access
        settings[:store_url] || settings[:store_base_url] || @hook.reference_id
      end
    end
  end
end
