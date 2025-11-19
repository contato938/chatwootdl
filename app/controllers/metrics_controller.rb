class MetricsController < ApplicationController
  # Skip authentication and authorization for metrics endpoint
  # This endpoint is typically accessed by monitoring systems (Prometheus, Datadog, etc.)
  skip_before_action :set_current_user
  skip_around_action :switch_locale
  skip_around_action :handle_with_exception

  def show
    # Return basic metrics in Prometheus format
    # This is a minimal implementation that can be extended later
    metrics = generate_basic_metrics

    render plain: metrics, content_type: 'text/plain; version=0.0.4', status: :ok
  end

  private

  def generate_basic_metrics
    # Generate basic application metrics
    # Format: # HELP, # TYPE, and metric lines following Prometheus exposition format
    [
      '# HELP chatwoot_up Application is running',
      '# TYPE chatwoot_up gauge',
      'chatwoot_up 1',
      '',
      '# HELP chatwoot_info Application version information',
      '# TYPE chatwoot_info gauge',
      "chatwoot_info{version=\"#{Chatwoot.config[:version]}\"} 1",
      '',
      '# HELP chatwoot_accounts_total Total number of accounts',
      '# TYPE chatwoot_accounts_total gauge',
      "chatwoot_accounts_total #{Account.count}",
      '',
      '# HELP chatwoot_users_total Total number of users',
      '# TYPE chatwoot_users_total gauge',
      "chatwoot_users_total #{User.count}",
      '',
      '# HELP chatwoot_conversations_total Total number of conversations',
      '# TYPE chatwoot_conversations_total gauge',
      "chatwoot_conversations_total #{Conversation.count}",
      ''
    ].join("\n")
  rescue StandardError => e
    # If metrics collection fails, return minimal valid response
    Rails.logger.error("Metrics collection failed: #{e.message}")
    [
      '# HELP chatwoot_up Application is running',
      '# TYPE chatwoot_up gauge',
      'chatwoot_up 1',
      ''
    ].join("\n")
  end
end
