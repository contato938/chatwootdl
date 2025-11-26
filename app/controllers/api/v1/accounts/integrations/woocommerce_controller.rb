class Api::V1::Accounts::Integrations::WoocommerceController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?, only: [:create, :test_connection, :destroy]
  before_action :fetch_hook, except: [:test_connection, :create]
  before_action :find_contact, only: [:orders]
  before_action :ensure_contact_identifiers, only: [:orders]

  def test_connection
    hook = build_test_hook
    client = Integrations::Woocommerce::Client.new(hook)
    result = client.test_connection

    if result[:success]
      render json: { success: true, message: 'Connection successful' }
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
    end
  end

  def create
    hook = Current.account.hooks.find_or_initialize_by(app_id: 'woocommerce')
    hook.settings = sanitized_settings
    hook.status = 'enabled'
    hook.reference_id = normalized_store_url
    hook.access_token = connection_params[:consumer_secret]

    test_result = Integrations::Woocommerce::Client.new(build_test_hook).test_connection
    unless test_result[:success]
      return render json: { success: false, error: test_result[:error] }, status: :unprocessable_entity
    end

    hook.save!
    render json: { success: true, hook: hook_response(hook) }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def products
    client = Integrations::Woocommerce::Client.new(@hook)
    result = client.list_products(
      page: params[:page].presence || 1,
      per_page: params[:per_page].presence || 20,
      search: params[:search],
      category: params[:category]
    )

    render json: result
  rescue StandardError => e
    Rails.logger.error("WooCommerce products error: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def orders
    result = Integrations::Ecommerce::WoocommerceProvider.new(@hook).list_orders(contact: @contact)
    render json: result
  rescue StandardError => e
    Rails.logger.error("WooCommerce orders error: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'woocommerce')
  end

  def build_test_hook
    Integrations::Hook.new(
      account: Current.account,
      app_id: 'woocommerce',
      settings: connection_params,
      reference_id: normalized_store_url,
      access_token: connection_params[:consumer_secret]
    )
  end

  def connection_params
    params.require(:settings).permit(
      :store_name,
      :store_url,
      :store_base_url,
      :consumer_key,
      :consumer_secret,
      :api_version,
      :verify_ssl,
      :request_timeout
    ).to_h
  end

  def sanitized_settings
    settings = connection_params.dup
    settings[:consumer_secret] = '[FILTERED]'
    settings[:store_url] = normalized_store_url if normalized_store_url
    settings[:verify_ssl] = ActiveModel::Type::Boolean.new.cast(settings.fetch(:verify_ssl, true))
    settings[:request_timeout] = settings[:request_timeout].to_i if settings[:request_timeout].present?
    settings.compact
  end

  def normalized_store_url
    url = connection_params[:store_url].presence || connection_params[:store_base_url]
    return if url.blank?

    url.to_s.strip.gsub(%r{/+$}, '')
  end

  def find_contact
    @contact = Current.account.contacts.find_by(id: params[:contact_id])
    return if @contact.present?

    render json: { error: 'Contact not found' }, status: :not_found
    false
  end

  def ensure_contact_identifiers
    return if @contact.present? && (@contact.email.present? || @contact.phone_number.present?)

    render json: { error: 'Contact information missing' }, status: :unprocessable_entity
    false
  end

  def hook_response(hook)
    {
      id: hook.id,
      app_id: hook.app_id,
      status: hook.enabled?,
      settings: hook.settings.with_indifferent_access.except(:consumer_secret, 'consumer_secret'),
      reference_id: hook.reference_id
    }
  end
end
