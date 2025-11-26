/* global axios */

import ApiClient from '../ApiClient';

class WoocommerceAPI extends ApiClient {
  constructor() {
    super('integrations/woocommerce', { accountScoped: true });
  }

  testConnection(settings) {
    return axios.post(`${this.url}/test_connection`, { settings });
  }

  saveSettings(settings) {
    return axios.post(`${this.url}`, { settings });
  }

  getProducts(params = {}) {
    return axios.get(`${this.url}/products`, { params });
  }

  getOrders(contactId) {
    return axios.get(`${this.url}/orders`, {
      params: { contact_id: contactId },
    });
  }
}

export default new WoocommerceAPI();
