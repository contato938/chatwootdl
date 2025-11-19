require 'rails_helper'

describe 'DashboardController', type: :request do
  describe 'onboarding flow' do
    after do
      # Clean up Redis key after each test
      Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
    end

    context 'when accessing root path' do
      context 'with no SuperAdmin users in database (fresh installation)' do
        before do
          # Ensure no SuperAdmin users exist
          SuperAdmin.destroy_all
        end

        it 'redirects to onboarding page' do
          get '/'
          expect(response).to redirect_to('/installation/onboarding')
        end

        it 'sets the Redis onboarding flag' do
          get '/'
          expect(Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)).to be_present
        end
      end

      context 'with SuperAdmin users existing (completed installation)' do
        let!(:super_admin) { create(:super_admin) }

        it 'does not redirect to onboarding page' do
          get '/'
          expect(response).to have_http_status(:success)
          expect(response).not_to redirect_to('/installation/onboarding')
        end

        it 'does not set the Redis onboarding flag' do
          get '/'
          expect(Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)).to be_nil
        end
      end

      context 'with Redis onboarding flag explicitly set' do
        let!(:super_admin) { create(:super_admin) }

        before do
          Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
        end

        it 'redirects to onboarding page even with SuperAdmin present' do
          get '/'
          expect(response).to redirect_to('/installation/onboarding')
        end
      end
    end
  end
end

describe '/app/login', type: :request do
  context 'without DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      get '/app/login'
      expect(response).to have_http_status(:success)
    end
  end

  context 'with DEFAULT_LOCALE' do
    it 'renders the dashboard' do
      with_modified_env DEFAULT_LOCALE: 'pt_BR' do
        get '/app/login'
        expect(response).to have_http_status(:success)
        expect(response.body).to include "selectedLocale: 'pt_BR'"
      end
    end
  end

  context 'with non-HTML format' do
    it 'returns not acceptable for JSON with error message' do
      get '/app/login', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:not_acceptable)
      expect(response.parsed_body).to eq({ 'error' => 'Please use API routes instead of dashboard routes for JSON requests' })
    end
  end

  # Routes are loaded once on app start
  # hence Rails.application.reload_routes! is used in this spec
  # ref : https://stackoverflow.com/a/63584877/939299
  context 'with CW_API_ONLY_SERVER true' do
    it 'returns 404' do
      with_modified_env CW_API_ONLY_SERVER: 'true' do
        Rails.application.reload_routes!
        get '/app/login'
        expect(response).to have_http_status(:not_found)
      end
      Rails.application.reload_routes!
    end
  end
end
