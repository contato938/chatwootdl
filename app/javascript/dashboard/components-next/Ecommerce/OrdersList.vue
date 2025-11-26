<script setup>
import { ref, watch, computed } from 'vue';
import { useFunctionGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import EcommerceAPI from 'dashboard/api/integrations/ecommerce';
import OrderItem from './OrderItem.vue';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const contact = useFunctionGetter('contacts/getContact', props.contactId);

const orders = ref([]);
const loading = ref(true);
const error = ref('');

const hasSearchableInfo = computed(
  () => !!contact.value?.email || !!contact.value?.phone_number
);

const displayError = computed(() => {
  if (!error.value) return '';
  if (error.value === 'Contact information missing') {
    return t('ECOMMERCE.ORDERS.MISSING_IDENTIFIERS');
  }
  if (error.value === 'Contact not found') {
    return t('ECOMMERCE.ORDERS.ERROR');
  }
  return error.value;
});

const fetchOrders = async () => {
  if (!hasSearchableInfo.value) {
    orders.value = [];
    loading.value = false;
    return;
  }

  try {
    loading.value = true;
    error.value = '';
    const response = await EcommerceAPI.getOrders(props.contactId);
    orders.value = response.data.orders || [];
  } catch (e) {
    error.value =
      e.response?.data?.error || t('ECOMMERCE.ORDERS.ERROR');
  } finally {
    loading.value = false;
  }
};

watch(
  () => props.contactId,
  () => {
    fetchOrders();
  },
  { immediate: true }
);

watch(
  hasSearchableInfo,
  value => {
    if (value && !orders.value.length && !loading.value) {
      fetchOrders();
    }
  },
  { immediate: false }
);
</script>

<template>
  <div class="px-4 py-2 text-n-slate-12">
    <div v-if="!hasSearchableInfo" class="text-center text-n-slate-12">
      {{ $t('ECOMMERCE.ORDERS.MISSING_IDENTIFIERS') }}
    </div>
    <div v-else-if="loading" class="flex justify-center items-center p-4">
      <Spinner size="32" class="text-n-brand" />
    </div>
  <div v-else-if="error" class="text-center text-n-ruby-12">
      {{ displayError }}
    </div>
    <div v-else-if="!orders.length" class="text-center text-n-slate-12">
      {{ $t('ECOMMERCE.ORDERS.NO_ORDERS') }}
    </div>
    <div v-else>
      <OrderItem v-for="order in orders" :key="order.id" :order="order" />
    </div>
  </div>
</template>
