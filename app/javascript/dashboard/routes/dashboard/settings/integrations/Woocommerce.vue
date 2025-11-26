<script setup>
import { ref, computed, onMounted } from 'vue';
import { useFunctionGetter, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import WoocommerceAPI from 'dashboard/api/integrations/woocommerce';

const store = useStore();
const integration = useFunctionGetter('integrations/getIntegration', 'woocommerce');
const { t } = useI18n();

const form = ref({
  storeUrl: '',
  consumerKey: '',
  consumerSecret: '',
});

const isTesting = ref(false);
const isSaving = ref(false);
const integrationLoaded = ref(false);
const connectionMessage = ref('');
const formError = ref('');
const showSecret = ref(false);

const existingHook = computed(() => integration.value.hooks?.[0]);
const isConnected = computed(() => !!existingHook.value?.status);
const integrationAction = computed(() =>
  isConnected.value ? 'disconnect' : 'connect'
);

const buildPayload = () => ({
  store_url: form.value.storeUrl?.trim(),
  consumer_key: form.value.consumerKey,
  consumer_secret: form.value.consumerSecret,
});

const prefillForm = () => {
  const settings = existingHook.value?.settings || {};
  form.value.storeUrl =
    settings.store_url ||
    settings.store_base_url ||
    existingHook.value?.reference_id ||
    '';
  form.value.consumerKey = settings.consumer_key || '';
  form.value.consumerSecret = '';
};

const loadIntegration = async () => {
  await store.dispatch('integrations/get', 'woocommerce');
  prefillForm();
  integrationLoaded.value = true;
};

const handleTestConnection = async () => {
  isTesting.value = true;
  connectionMessage.value = '';
  formError.value = '';
  try {
    const { data } = await WoocommerceAPI.testConnection(buildPayload());
    if (data.success) {
      connectionMessage.value = t('WOOCOMMERCE.MESSAGES.TEST_SUCCESS');
      useAlert(connectionMessage.value);
    } else {
      formError.value =
        data.error || t('WOOCOMMERCE.MESSAGES.TEST_ERROR');
    }
  } catch (error) {
    formError.value =
      error.response?.data?.error ||
      t('WOOCOMMERCE.MESSAGES.TEST_ERROR');
  } finally {
    isTesting.value = false;
  }
};

const handleSave = async () => {
  isSaving.value = true;
  connectionMessage.value = '';
  formError.value = '';
  try {
    const { data } = await WoocommerceAPI.saveSettings(buildPayload());
    if (data.success) {
      connectionMessage.value = t('WOOCOMMERCE.MESSAGES.SAVE_SUCCESS');
      useAlert(connectionMessage.value);
      form.value.consumerSecret = '';
      await store.dispatch('integrations/get', 'woocommerce');
      prefillForm();
    } else {
      formError.value =
        data.error || t('WOOCOMMERCE.MESSAGES.SAVE_ERROR');
    }
  } catch (error) {
    formError.value =
      error.response?.data?.error ||
      t('WOOCOMMERCE.MESSAGES.SAVE_ERROR');
  } finally {
    isSaving.value = false;
  }
};

onMounted(() => {
  loadIntegration();
});
</script>

<template>
  <div class="flex-grow flex-shrink p-4 overflow-auto max-w-6xl mx-auto">
    <div v-if="integrationLoaded" class="flex flex-col gap-6">
      <Integration
        :integration-id="integration.id"
        :integration-logo="integration.logo"
        :integration-name="integration.name"
        :integration-description="integration.description"
        :integration-enabled="isConnected"
        :integration-action="integrationAction"
        :delete-confirmation-text="{
          title: $t('INTEGRATION_SETTINGS.DELETE.CONFIRM.TITLE'),
          message: $t('WOOCOMMERCE.MESSAGES.DISCONNECT_CONFIRM'),
        }"
      />

      <div class="outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow p-6 space-y-6">
        <div class="flex items-start justify-between gap-4 flex-wrap">
          <div class="space-y-1">
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ $t('WOOCOMMERCE.TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ $t('WOOCOMMERCE.SUBTITLE') }}
            </p>
            <p v-if="connectionMessage" class="text-xs text-n-teal-10">
              {{ connectionMessage }}
            </p>
            <p v-if="formError" class="text-xs text-n-ruby-10">
              {{ formError }}
            </p>
          </div>
          <div class="flex items-center gap-3">
            <a
              :href="$t('WOOCOMMERCE.HELP.DOCS_LINK')"
              target="_blank"
              rel="noreferrer"
              class="text-sm text-n-blue-text underline underline-offset-4"
            >
              {{ $t('WOOCOMMERCE.ACTIONS.VIEW_DOCS') }}
            </a>
            <Button
              v-if="isConnected"
              slate
              ghost
              :label="$t('WOOCOMMERCE.STATUS.CONNECTED')"
              class="cursor-default"
            />
          </div>
        </div>

        <form class="grid grid-cols-1 md:grid-cols-2 gap-4" @submit.prevent="handleSave">
          <Input
            v-model="form.storeUrl"
            :label="$t('WOOCOMMERCE.FORM.STORE_URL.LABEL')"
            :placeholder="$t('WOOCOMMERCE.FORM.STORE_URL.PLACEHOLDER')"
            :message="$t('WOOCOMMERCE.FORM.STORE_URL.HELP')"
            class="md:col-span-2"
            autocomplete="url"
            required
          />
          <Input
            v-model="form.consumerKey"
            :label="$t('WOOCOMMERCE.FORM.CONSUMER_KEY.LABEL')"
            :placeholder="$t('WOOCOMMERCE.FORM.CONSUMER_KEY.PLACEHOLDER')"
            :message="$t('WOOCOMMERCE.FORM.CONSUMER_KEY.HELP')"
            autocomplete="off"
            required
          />
          <div class="relative">
            <Input
              v-model="form.consumerSecret"
              :label="$t('WOOCOMMERCE.FORM.CONSUMER_SECRET.LABEL')"
              :placeholder="$t('WOOCOMMERCE.FORM.CONSUMER_SECRET.PLACEHOLDER')"
              :message="$t('WOOCOMMERCE.FORM.CONSUMER_SECRET.HELP')"
              :type="showSecret ? 'text' : 'password'"
              autocomplete="off"
              required
            />
            <button
              type="button"
              class="absolute right-3 top-[38px] text-n-slate-9 hover:text-n-slate-12"
              @click="showSecret = !showSecret"
            >
              <i
                :class="showSecret ? 'i-ph-eye-slash' : 'i-ph-eye'"
                class="text-lg"
              />
            </button>
          </div>
          <div class="md:col-span-2 flex justify-end gap-2">
            <Button
              type="button"
              slate
              faded
              :is-loading="isTesting"
              :label="
                isTesting
                  ? $t('WOOCOMMERCE.ACTIONS.TESTING')
                  : $t('WOOCOMMERCE.ACTIONS.TEST_CONNECTION')
              "
              @click="handleTestConnection"
            />
            <Button
              type="submit"
              :is-loading="isSaving"
              :label="
                isSaving
                  ? $t('WOOCOMMERCE.ACTIONS.SAVING')
                  : $t('WOOCOMMERCE.ACTIONS.SAVE')
              "
            />
          </div>
        </form>
      </div>
    </div>
    <div v-else class="flex items-center justify-center flex-1">
      <Spinner size="" color-scheme="primary" />
    </div>
  </div>
</template>
