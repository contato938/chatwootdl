<script setup>
import { computed } from 'vue';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const formatDate = dateString => {
  if (!dateString) return '';
  return format(new Date(dateString), 'MMM d, yyyy');
};

const formatCurrency = (amount, currency) => {
  if (!amount) return '-';
  const value = Number.parseFloat(amount);
  if (Number.isNaN(value)) return amount;

  return new Intl.NumberFormat('en', {
    style: 'currency',
    currency: currency || 'USD',
  }).format(value);
};

const translatedStatus = computed(() => {
  const status = props.order.financial_status || props.order.status;
  if (!status) {
    return '';
  }

  const key = status.toString().toUpperCase();
  return t(`ECOMMERCE.ORDERS.STATUS.${key}`, status);
});

const translatedFulfillmentStatus = computed(() => {
  const status = props.order.fulfillment_status;
  if (!status) {
    return '';
  }

  const key = status.toString().toUpperCase();
  return t(`ECOMMERCE.ORDERS.FULFILLMENT.${key}`, status);
});

const statusClass = status => {
  const normalized = status?.toString().toLowerCase();
  const statusMap = {
    paid: 'bg-n-teal-5 text-n-teal-12',
    completed: 'bg-n-teal-5 text-n-teal-12',
    processing: 'bg-n-amber-4 text-n-amber-11',
    pending: 'bg-n-solid-3 text-n-slate-12',
    cancelled: 'bg-n-ruby-3 text-n-ruby-11',
    refunded: 'bg-n-blue-3 text-n-blue-11',
    failed: 'bg-n-ruby-3 text-n-ruby-11',
  };

  return statusMap[normalized] || 'bg-n-solid-3 text-n-slate-12';
};

const fulfillmentClass = status => {
  const normalized = status?.toString().toLowerCase();
  const fulfillmentMap = {
    fulfilled: 'text-n-teal-9',
    partially_fulfilled: 'text-n-amber-9',
    unfulfilled: 'text-n-slate-11',
  };

  return fulfillmentMap[normalized] || 'text-n-slate-11';
};

const providerLabel = computed(() => {
  if (!props.order.provider) {
    return '';
  }
  const key = props.order.provider.toString().toUpperCase();
  return t(`ECOMMERCE.PRODUCTS.PROVIDER.${key}`, props.order.provider);
});
</script>

<template>
  <div
    class="py-3 border-b border-n-weak last:border-b-0 flex flex-col gap-1.5"
  >
    <div class="flex justify-between items-center gap-2">
      <div class="font-medium flex">
        <a
          v-if="order.order_url"
          :href="order.order_url"
          target="_blank"
          rel="noopener noreferrer"
          class="hover:underline text-n-slate-12 cursor-pointer truncate flex items-center gap-2"
        >
          {{
            $t('ECOMMERCE.ORDERS.ORDER_ID', {
              id: order.order_number || order.id,
            })
          }}
          <i class="i-lucide-external-link text-sm" />
        </a>
        <span v-else class="text-n-slate-12">
          {{
            $t('ECOMMERCE.ORDERS.ORDER_ID', {
              id: order.order_number || order.id,
            })
          }}
        </span>
      </div>
      <div
        v-if="translatedStatus"
        :class="statusClass(order.financial_status || order.status)"
        class="text-xs px-2 py-1 rounded capitalize truncate"
        :title="translatedStatus"
      >
        {{ translatedStatus }}
      </div>
    </div>
    <div class="text-sm text-n-slate-12 flex flex-wrap gap-2">
      <span v-if="order.created_at" class="text-n-slate-11 border-r border-n-weak pr-2">
        {{ formatDate(order.created_at) }}
      </span>
      <span class="text-n-slate-11">
        {{ formatCurrency(order.total_price, order.currency) }}
      </span>
    </div>
    <div v-if="translatedFulfillmentStatus">
      <span
        :class="fulfillmentClass(order.fulfillment_status)"
        class="capitalize font-medium text-sm"
        :title="translatedFulfillmentStatus"
      >
        {{ translatedFulfillmentStatus }}
      </span>
    </div>
    <div v-if="providerLabel" class="text-xs text-n-slate-11 flex items-center gap-1">
      <i class="i-ph-storefront text-n-slate-10" />
      <span>{{ providerLabel }}</span>
    </div>
  </div>
</template>
