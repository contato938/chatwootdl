class GlobalConfig
  VERSION = 'V1'.freeze
  KEY_PREFIX = 'GLOBAL_CONFIG'.freeze
  DEFAULT_EXPIRY = 1.day

  class << self
    def get(*args)
      config_keys = *args
      config = {}

      config_keys.each do |config_key|
        config[config_key] = load_from_cache(config_key)
      end

      typecast_config(config)
      config.with_indifferent_access
    end

    def get_value(arg)
      load_from_cache(arg)
    end

    def clear_cache
      begin
        cached_keys = $alfred.with { |conn| conn.keys("#{VERSION}:#{KEY_PREFIX}:*") }
        (cached_keys || []).each do |cached_key|
          $alfred.with { |conn| conn.expire(cached_key, 0) }
        end
      rescue => e
        Rails.logger.error "Error clearing cache: #{e.message}"
      end
    end

    private

    def typecast_config(config)
      begin
        general_configs = ConfigLoader.new.general_configs
        config.each do |config_key, config_value|
          config_type = general_configs.find { |c| c['name'] == config_key }&.dig('type')
          config[config_key] = ActiveRecord::Type::Boolean.new.cast(config_value) if config_type == 'boolean'
        end
      rescue => e
        Rails.logger.error "Error typecasting config: #{e.message}"
      end
    end

    def load_from_cache(config_key)
      cache_key = "#{VERSION}:#{KEY_PREFIX}:#{config_key}"
      cached_value = nil
      
      begin
        cached_value = $alfred.with { |conn| conn.get(cache_key) }
      rescue => e
        Rails.logger.error "Error loading from cache for key #{config_key}: #{e.message}"
      end

      if cached_value.blank?
        value_from_db = db_fallback(config_key)
        cached_value = { value: value_from_db }.to_json
        begin
          $alfred.with { |conn| conn.set(cache_key, cached_value, { ex: DEFAULT_EXPIRY }) }
        rescue => e
          Rails.logger.error "Error setting cache for key #{config_key}: #{e.message}"
        end
      end

      begin
        JSON.parse(cached_value)['value']
      rescue => e
        Rails.logger.error "Error parsing cached value for key #{config_key}: #{e.message}"
        db_fallback(config_key)
      end
    end

    def db_fallback(config_key)
      begin
        InstallationConfig.find_by(name: config_key)&.value
      rescue => e
        Rails.logger.error "Error loading config from database for key #{config_key}: #{e.message}"
        nil
      end
    end
  end
end
