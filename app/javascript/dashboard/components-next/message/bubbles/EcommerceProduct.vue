<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import { useMessageContext } from 'dashboard/components-next/message/provider.js';
import { useI18n } from 'vue-i18n';

const { contentAttributes } = useMessageContext();
const { t } = useI18n();

const product = computed(() => contentAttributes.value?.product || {});

const formatPrice = price => {
  if (!price) return '';
  const value = Number.parseFloat(price);
  if (Number.isNaN(value)) return price;

  return new Intl.NumberFormat('en', {
    style: 'currency',
    currency: 'USD',
  }).format(value);
};

const stockClass = computed(() => {
  const status = product.value.stock_status;
  if (status === 'in_stock') return 'bg-n-jade-3 text-n-jade-11';
  if (status) return 'bg-n-ruby-3 text-n-ruby-11';
  return 'bg-n-solid-3 text-n-slate-11';
});

const providerLabel = computed(() => {
  if (!product.value.provider) return '';
  const key = product.value.provider.toString().toUpperCase();
  return t(`ECOMMERCE.PRODUCTS.PROVIDER.${key}`, product.value.provider);
});
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="ecommerce-product">
    <div class="flex gap-3">
      <div
        v-if="product.thumbnail_url"
        class="flex-shrink-0 w-16 h-16 bg-n-solid-3 rounded-md overflow-hidden"
      >
        <img
          :src="product.thumbnail_url"
          :alt="product.name"
          class="w-full h-full object-cover"
        />
      </div>
      <div
        v-else
        class="flex-shrink-0 w-16 h-16 bg-n-solid-3 rounded-md flex items-center justify-center"
      >
        <i class="i-ph-package text-2xl text-n-slate-9" />
      </div>

      <div class="flex-1 min-w-0">
        <p class="text-sm font-semibold text-n-slate-12 truncate">
          {{ product.name }}
        </p>
        <div class="flex items-center gap-2 text-xs text-n-slate-11 mt-0.5">
          <span v-if="product.price" class="font-medium">
            {{ formatPrice(product.price) }}
          </span>
          <span v-if="product.sku" class="text-n-slate-10">•</span>
          <span v-if="product.sku">{{ product.sku }}</span>
          <span
            v-if="providerLabel"
            class="flex items-center gap-1 text-n-slate-10"
          >
            <i class="i-ph-storefront-bold" />
            {{ providerLabel }}
          </span>
        </div>
        <div class="flex items-center justify-between gap-2 mt-2">
          <span
            class="text-xs px-2 py-0.5 rounded-full"
            :class="stockClass"
          >
            {{
              product.stock_status === 'in_stock'
                ? $t('ECOMMERCE.PRODUCTS.IN_STOCK')
                : $t('ECOMMERCE.PRODUCTS.OUT_OF_STOCK')
            }}
          </span>
          <a
            v-if="product.product_url"
            :href="product.product_url"
            target="_blank"
            rel="noopener noreferrer"
            class="text-xs font-medium text-n-brand hover:underline flex items-center gap-1"
          >
            {{ $t('ECOMMERCE.PRODUCTS.VIEW') }}
            <i class="i-lucide-external-link text-sm" />
          </a>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
