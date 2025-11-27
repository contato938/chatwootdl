<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div class="border-b border-slate-200 dark:border-slate-700 px-4 py-4">
      <!-- Breadcrumb -->
      <div class="flex items-center text-sm text-slate-500 dark:text-slate-400 mb-2">
        <router-link :to="`/app/accounts/${currentAccountId}/dashboard`" class="hover:text-slate-700 dark:hover:text-slate-300">
          Dashboard
        </router-link>
        <span class="mx-2">/</span>
        <span class="text-slate-900 dark:text-slate-50 font-medium">{{ $t('SALES_PIPELINE.TITLE') }}</span>
      </div>
      
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-3">
          <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-50">
            {{ $t('SALES_PIPELINE.TITLE') }}
          </h2>
          <router-link
            :to="settingsRoute"
            class="inline-flex items-center px-2 py-1 text-xs font-medium text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-50 rounded hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <fluent-icon icon="settings" size="14" class="mr-1" />
            {{ $t('SALES_PIPELINE.CONFIGURE') }}
          </router-link>
        </div>
        
        <!-- Filters -->
        <div class="flex items-center space-x-3">
          <div class="flex items-center space-x-2">
            <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
              {{ $t('SALES_PIPELINE.FILTER_BY_CHANNEL') }}
            </label>
            <select
              v-model="filters.inbox_id"
              class="h-8 pl-3 pr-8 text-sm bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-md focus:outline-none focus:ring-1 focus:ring-woot-500 focus:border-woot-500"
              @change="loadKanbanData"
            >
              <option value="">
                {{ $t('SALES_PIPELINE.ALL_CHANNELS') }}
              </option>
              <option
                v-for="inbox in inboxes"
                :key="inbox.id"
                :value="inbox.id"
              >
                {{ inbox.name }}
              </option>
            </select>
          </div>

          <div class="flex items-center space-x-2">
            <label class="text-sm font-medium text-slate-700 dark:text-slate-300">
              {{ $t('SALES_PIPELINE.FILTER_BY_AGENT') }}
            </label>
            <select
              v-model="filters.assignee_id"
              class="h-8 pl-3 pr-8 text-sm bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-md focus:outline-none focus:ring-1 focus:ring-woot-500 focus:border-woot-500"
              @change="loadKanbanData"
            >
              <option value="">
                {{ $t('SALES_PIPELINE.ALL_AGENTS') }}
              </option>
              <option
                v-for="agent in agents"
                :key="agent.id"
                :value="agent.id"
              >
                {{ agent.name }}
              </option>
            </select>
          </div>

          <button
            class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors disabled:opacity-50"
            @click="loadKanbanData"
            :disabled="uiFlags.isFetching"
          >
            <fluent-icon v-if="!uiFlags.isFetching" icon="arrow-sync" size="14" class="mr-1" />
            <spinner v-else size="small" />
            {{ $t('SALES_PIPELINE.REFRESH') }}
          </button>
        </div>
      </div>
    </div>

    <!-- Kanban Board -->
    <div class="flex-1 overflow-x-auto">
      <div v-if="uiFlags.isFetching" class="flex items-center justify-center h-64">
        <spinner size="large" />
      </div>

      <div
        v-else-if="stages.length === 0"
        class="flex flex-col items-center justify-center h-64 text-center px-4"
      >
        <div class="mb-4">
          <fluent-icon icon="board" size="48" class="text-slate-300 dark:text-slate-600" />
        </div>
        <div class="text-lg font-semibold text-slate-900 dark:text-slate-50 mb-2">
          {{ $t('SALES_PIPELINE.NO_STAGES_CONFIGURED') }}
        </div>
        <div class="text-sm text-slate-500 dark:text-slate-400 mb-6 max-w-md">
          {{ $t('SALES_PIPELINE.CONFIGURE_STAGES_FIRST') }}
        </div>
        <router-link
          :to="settingsRoute"
          class="inline-flex items-center px-4 py-2 bg-woot-500 hover:bg-woot-600 text-white rounded-lg font-medium transition-colors"
        >
          <fluent-icon icon="settings" size="16" class="mr-2" />
          {{ $t('SALES_PIPELINE.CONFIGURE_PIPELINE') }}
        </router-link>
      </div>

      <div v-else class="inline-flex h-full p-4 space-x-4 min-w-max">
        <div
          v-for="stage in kanbanData"
          :key="stage.stage_id"
          class="flex-shrink-0 w-80 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <!-- Column Header -->
          <div
            class="px-4 py-3 border-b border-slate-200 dark:border-slate-700 rounded-t-lg"
            :style="{ backgroundColor: stage.color + '20', borderColor: stage.color }"
          >
            <div class="flex items-center justify-between mb-1">
              <h3 class="font-medium text-slate-900 dark:text-slate-50">
                {{ stage.name }}
              </h3>
              <span
                class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300"
              >
                {{ stage.cards_count }}
              </span>
            </div>
            <div v-if="stage.is_default || stage.is_closed_won || stage.is_closed_lost" class="flex gap-1 mt-1">
              <span
                v-if="stage.is_default"
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-400"
              >
                {{ $t('SALES_PIPELINE.BADGES.DEFAULT') }}
              </span>
              <span
                v-if="stage.is_closed_won"
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300"
              >
                ✓ {{ $t('SALES_PIPELINE.BADGES.WON') }}
              </span>
              <span
                v-if="stage.is_closed_lost"
                class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300"
              >
                ✗ {{ $t('SALES_PIPELINE.BADGES.LOST') }}
              </span>
            </div>
          </div>

          <!-- Cards Container -->
          <draggable
            :list="stage.cards"
            :group="{ name: 'kanban', pull: true, put: true }"
            item-key="conversation_id"
            class="p-3 space-y-2 min-h-[400px] max-h-[600px] overflow-y-auto"
            @change="event => handleCardChange(stage, event)"
          >
            <template #item="{ element }">
              <div
                class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg p-3 cursor-pointer hover:shadow-md transition-shadow"
                @click="openConversation(element.conversation_id)"
              >
                <div class="flex items-start justify-between mb-2">
                  <div class="flex items-center space-x-2">
                    <div class="w-6 h-6 rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center">
                      <span class="text-xs font-medium text-slate-600 dark:text-slate-300">
                        {{ element.contact_name.charAt(0).toUpperCase() }}
                      </span>
                    </div>
                    <div>
                      <div class="text-sm font-medium text-slate-900 dark:text-slate-50">
                        {{ element.contact_name }}
                      </div>
                      <div class="text-xs text-slate-500 dark:text-slate-400">
                        {{ element.inbox_name }}
                      </div>
                    </div>
                  </div>
                </div>

                <div class="text-sm text-slate-600 dark:text-slate-400 mb-2 line-clamp-2">
                  {{ element.last_message_snippet || $t('SALES_PIPELINE.NO_MESSAGES') }}
                </div>

                <div class="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                  <div>{{ element.assignee_name }}</div>
                  <div>{{ dynamicTime(element.last_activity_at) }}</div>
                </div>
              </div>
            </template>
          </draggable>

          <div
            v-if="stage.cards.length === 0"
            class="text-center text-slate-400 dark:text-slate-500 text-sm py-8"
          >
            {{ $t('SALES_PIPELINE.NO_CARDS_IN_STAGE') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { frontendURL } from 'dashboard/helper/URLHelper';
import FluentIcon from 'shared/components/FluentIcon.vue';
import draggable from 'vuedraggable';

export default {
  name: 'SalesPipelineIndex',
  components: {
    Spinner,
    FluentIcon,
    draggable,
  },
  data() {
    return {
      filters: {
        inbox_id: '',
        assignee_id: '',
        status: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'salesPipeline/getUIFlags',
      stages: 'salesPipeline/getStages',
      kanbanData: 'salesPipeline/getKanbanData',
      inboxes: 'inboxes/getInboxes',
      agents: 'agents/getAgents',
      currentAccountId: 'getCurrentAccountId',
    }),
    settingsRoute() {
      return frontendURL(`accounts/${this.currentAccountId}/settings/sales-pipeline`);
    },
  },
  mounted() {
    this.loadInitialData();
  },
  methods: {
    async loadInitialData() {
      try {
        await this.$store.dispatch('salesPipeline/fetchSalesPipeline', {
          accountId: this.currentAccountId,
        });
        await this.loadKanbanData();
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE.ERROR.LOAD_FAILED'));
      }
    },

    async loadKanbanData() {
      try {
        await this.$store.dispatch('salesPipeline/fetchKanbanData', {
          accountId: this.currentAccountId,
          filters: this.filters,
        });
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE.ERROR.KANBAN_LOAD_FAILED'));
      }
    },

    openConversation(conversationId) {
      // Usa rota padrão de conversa direta pelo ID (display_id)
      const routeData = this.$router.resolve({
        name: 'inbox_conversation',
        params: {
          accountId: this.currentAccountId,
          conversation_id: conversationId,
        },
      });
      window.open(routeData.href, '_blank');
    },

    showErrorMessage(message) {
      this.$root.$emit('newToastMessage', {
        message,
        type: 'error',
      });
    },

    dynamicTime(time) {
      return dynamicTime(time);
    },

    async handleCardChange(stage, event) {
      if (!event?.added?.element) return;
      const card = event.added.element;
      try {
        await this.$store.dispatch('salesPipeline/updateConversationStage', {
          accountId: this.currentAccountId,
          conversationId: card.conversation_id,
          stageId: stage.stage_id,
        });
        await this.loadKanbanData();
      } catch (error) {
        this.showErrorMessage(this.$t('SALES_PIPELINE.ERROR.KANBAN_LOAD_FAILED'));
        await this.loadKanbanData();
      }
    },
  },
};
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
