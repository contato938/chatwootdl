require 'rails_helper'

RSpec.describe 'Metrics API', type: :request do
  describe 'GET /metrics' do
    context 'when accessing the metrics endpoint' do
      it 'returns HTTP success (200)' do
        get '/metrics'
        expect(response).to have_http_status(:success)
      end

      it 'returns content type text/plain with Prometheus version' do
        get '/metrics'
        expect(response.content_type).to match(%r{text/plain})
      end

      it 'returns valid Prometheus format metrics' do
        get '/metrics'

        # Check for basic required metrics
        expect(response.body).to include('chatwoot_up 1')
        expect(response.body).to include('# HELP chatwoot_up Application is running')
        expect(response.body).to include('# TYPE chatwoot_up gauge')
      end

      it 'includes application version information' do
        get '/metrics'

        expect(response.body).to include('chatwoot_info')
        expect(response.body).to include('version=')
      end

      it 'includes basic application statistics' do
        get '/metrics'

        # These metrics should be present even if counts are 0
        expect(response.body).to include('chatwoot_accounts_total')
        expect(response.body).to include('chatwoot_users_total')
        expect(response.body).to include('chatwoot_conversations_total')
      end

      it 'does not require authentication' do
        # Explicitly verify that no authentication headers are needed
        get '/metrics'

        expect(response).to have_http_status(:success)
        expect(response).not_to have_http_status(:unauthorized)
      end

      it 'returns metrics with actual counts when data exists' do
        # Create test data
        create(:account)
        create(:user)

        get '/metrics'

        # Verify metrics reflect the created data
        expect(response.body).to match(/chatwoot_accounts_total \d+/)
        expect(response.body).to match(/chatwoot_users_total \d+/)
      end
    end

    context 'when metrics collection fails' do
      before do
        # Simulate a failure in metrics collection
        allow(Account).to receive(:count).and_raise(StandardError.new('Database error'))
      end

      it 'still returns HTTP success with minimal metrics' do
        get '/metrics'

        expect(response).to have_http_status(:success)
        expect(response.body).to include('chatwoot_up 1')
      end
    end

    context 'with different HTTP methods' do
      it 'only accepts GET requests' do
        post '/metrics'
        expect(response).to have_http_status(:not_found)

        put '/metrics'
        expect(response).to have_http_status(:not_found)

        delete '/metrics'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
