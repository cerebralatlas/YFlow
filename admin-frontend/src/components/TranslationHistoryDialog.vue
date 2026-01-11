<template>
  <el-dialog
    v-model="visible"
    :title="title"
    width="1000px"
    :close-on-click-modal="false"
    destroy-on-close
    class="translation-history-dialog"
    @closed="handleClosed"
  >
    <!-- 筛选工具栏 -->
    <div class="filter-toolbar">
      <div class="filter-left">
        <el-input
          v-model="filters.keyword"
          placeholder="搜索翻译键..."
          clearable
          prefix-icon="Search"
          class="filter-input"
          @input="handleSearch"
        />
        <el-select
          v-model="filters.operation"
          placeholder="操作类型"
          clearable
          class="filter-select"
          @change="loadHistory"
        >
          <el-option label="全部" value="" />
          <el-option label="创建" value="create" />
          <el-option label="修改" value="update" />
          <el-option label="删除" value="delete" />
        </el-select>
        <el-date-picker
          v-model="dateRange"
          type="daterange"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
          class="filter-date-picker"
          format="YYYY-MM-DD"
          value-format="YYYY-MM-DD"
          @change="handleDateChange"
        />
      </div>
      <div class="filter-right">
        <el-button :icon="Refresh" @click="handleRefresh">刷新</el-button>
      </div>
    </div>

    <!-- 空状态 -->
    <div v-if="!loading && histories.length === 0" class="empty-state">
      <el-icon :size="64" class="empty-icon"><DocumentCopy /></el-icon>
      <h3 class="empty-title">暂无历史记录</h3>
      <p class="empty-description">该翻译还没有操作历史</p>
    </div>

    <!-- 历史记录表格 -->
    <div v-else class="history-table-container">
      <el-table
        v-loading="loading"
        :data="histories"
        class="history-table"
        :empty-text="'加载中...'"
      >
        <!-- 翻译键列 -->
        <el-table-column prop="key_name" label="翻译键" width="200" show-overflow-tooltip>
          <template #default="{ row }">
            <span class="key-text">{{ row.key_name }}</span>
          </template>
        </el-table-column>

        <!-- 操作类型列 -->
        <el-table-column prop="operation" label="操作类型" width="120" align="center">
          <template #default="{ row }">
            <el-tag :class="['operation-tag', `operation-${row.operation}`]">
              {{ operationLabels[row.operation] }}
            </el-tag>
          </template>
        </el-table-column>

        <!-- 旧值列 -->
        <el-table-column prop="old_value" label="旧值" min-width="180" show-overflow-tooltip>
          <template #default="{ row }">
            <span v-if="row.operation !== 'create'" class="value-text old-value">
              {{ row.old_value || '-' }}
            </span>
            <span v-else class="value-text placeholder">-</span>
          </template>
        </el-table-column>

        <!-- 新值列 -->
        <el-table-column prop="new_value" label="新值" min-width="180" show-overflow-tooltip>
          <template #default="{ row }">
            <span v-if="row.operation !== 'delete'" class="value-text new-value">
              {{ row.new_value || '-' }}
            </span>
            <span v-else class="value-text placeholder">-</span>
          </template>
        </el-table-column>

        <!-- 操作人列 -->
        <el-table-column prop="operated_by" label="操作人" width="140" align="center">
          <template #default="{ row }">
            <div class="user-info">
              <el-avatar :size="28" class="user-avatar">
                {{ getUserInitial(row.operated_by) }}
              </el-avatar>
              <span class="user-name">用户 {{ row.operated_by }}</span>
            </div>
          </template>
        </el-table-column>

        <!-- 操作时间列 -->
        <el-table-column prop="operated_at" label="操作时间" width="180" align="center">
          <template #default="{ row }">
            <span class="time-text">{{ formatTime(row.operated_at) }}</span>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div v-if="meta.total_count > 0" class="pagination-container">
      <el-pagination
        v-model:current-page="currentPage"
        v-model:page-size="pageSize"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        :total="meta.total_count"
        @size-change="loadHistory"
        @current-change="loadHistory"
      />
    </div>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import {
  getTranslationHistory,
  getProjectTranslationHistory,
  getUserTranslationHistory,
} from '@/services/translation'
import type { TranslationHistory, TranslationHistoryQueryParams, TranslationHistoryListResponse } from '@/types/translation'
import { DocumentCopy, Refresh } from '@element-plus/icons-vue'

// Props
interface Props {
  modelValue: boolean
  mode?: 'translation' | 'project' | 'user'
  translationId?: number
  projectId?: number
  userId?: number
  keyName?: string
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  mode: 'translation',
  translationId: undefined,
  projectId: undefined,
  userId: undefined,
  keyName: undefined,
})

// Emits
const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'closed': []
}>()

// State
const visible = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const loading = ref(false)
const histories = ref<TranslationHistory[]>([])
const meta = ref({
  page: 1,
  page_size: 10,
  total_count: 0,
  total_pages: 0,
})

// Filters
const filters = ref<TranslationHistoryQueryParams>({
  page: 1,
  page_size: 10,
  operation: '',
  keyword: '',
  start_date: '',
  end_date: '',
})

const dateRange = ref<[string, string] | null>(null)
const currentPage = ref(1)
const pageSize = ref(10)
const initialKeyword = ref('') // 保存初始的翻译键名

// Computed
const title = computed(() => {
  if (props.mode === 'translation') {
    return props.keyName
      ? `翻译历史 - ${props.keyName}`
      : '翻译历史'
  } else if (props.mode === 'project') {
    return '项目翻译历史'
  } else if (props.mode === 'user') {
    return '用户操作历史'
  }
  return '翻译历史'
})

const operationLabels: Record<string, string> = {
  create: '创建',
  update: '修改',
  delete: '删除',
}

// Methods
const loadHistory = async () => {
  if (!props.translationId && !props.projectId && !props.userId) return

  loading.value = true

  try {
    const params = {
      page: currentPage.value,
      page_size: pageSize.value,
      operation: filters.value.operation || undefined,
      keyword: (filters.value.keyword || initialKeyword.value) || undefined,
      start_date: filters.value.start_date || undefined,
      end_date: filters.value.end_date || undefined,
    }

    let response: TranslationHistoryListResponse | undefined

    if (props.mode === 'translation' && props.translationId) {
      response = await getTranslationHistory(props.translationId, params)
    } else if (props.mode === 'project' && props.projectId) {
      response = await getProjectTranslationHistory(props.projectId, params)
    } else if (props.mode === 'user' && props.userId) {
      response = await getUserTranslationHistory(props.userId, params)
    }

    if (response) {
      histories.value = response.histories
      meta.value = response.meta
    }
  } catch (err: any) {
    console.error('Failed to load translation history:', err)
    histories.value = []
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  currentPage.value = 1
  loadHistory()
}

const handleDateChange = (value: [string, string] | null) => {
  if (value) {
    filters.value.start_date = value[0]
    filters.value.end_date = value[1]
  } else {
    filters.value.start_date = ''
    filters.value.end_date = ''
  }
  currentPage.value = 1
  loadHistory()
}

const handleRefresh = () => {
  loadHistory()
}

const handleClosed = () => {
  emit('closed')
}

const formatTime = (timeStr: string) => {
  if (!timeStr) return ''
  const date = new Date(timeStr)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
}

const getUserInitial = (userId: number) => {
  return `U${userId}`
}

// Watch for dialog open
watch(
  () => props.modelValue,
  (newVal) => {
    if (newVal) {
      currentPage.value = 1
      pageSize.value = 10

      // 如果是项目模式且有 keyName，自动设置为初始筛选
      if (props.mode === 'project' && props.keyName) {
        initialKeyword.value = props.keyName
      } else {
        initialKeyword.value = ''
      }

      filters.value = {
        page: 1,
        page_size: 10,
        operation: '',
        keyword: '',
        start_date: '',
        end_date: '',
      }
      dateRange.value = null
      loadHistory()
    }
  }
)

// Watch page size changes
watch(pageSize, () => {
  currentPage.value = 1
})
</script>

<style scoped>
/* 对话框样式 */
:deep(.translation-history-dialog .el-dialog) {
  border-radius: 16px;
  overflow: hidden;
}

:deep(.translation-history-dialog .el-dialog__header) {
  padding: 24px 24px 16px;
  border-bottom: 1px solid #f1f5f9;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
}

:deep(.translation-history-dialog .el-dialog__title) {
  font-size: 18px;
  font-weight: 700;
  color: #0f172a;
}

:deep(.translation-history-dialog .el-dialog__body) {
  padding: 0;
}

/* 筛选工具栏 */
.filter-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  background: #ffffff;
  border-bottom: 1px solid #f1f5f9;
  gap: 16px;
  flex-wrap: wrap;
}

.filter-left {
  display: flex;
  gap: 12px;
  flex: 1;
  min-width: 280px;
  flex-wrap: wrap;
}

.filter-right {
  flex-shrink: 0;
}

.filter-input,
.filter-select,
.filter-date-picker {
  flex-shrink: 0;
}

.filter-input {
  width: 220px;
}

.filter-select {
  width: 140px;
}

.filter-date-picker {
  width: 280px;
}

:deep(.filter-input .el-input__wrapper),
:deep(.filter-select .el-input__wrapper) {
  border-radius: 10px;
  box-shadow: none;
  border: 1px solid #e2e8f0;
  transition: all 0.2s ease;
}

:deep(.filter-input .el-input__wrapper:hover),
:deep(.filter-select .el-input__wrapper:hover) {
  border-color: #cbd5e1;
}

:deep(.filter-input .el-input__wrapper.is-focus),
:deep(.filter-select .el-input__wrapper.is-focus) {
  border-color: #06b6d4;
  box-shadow: 0 0 0 3px rgba(6, 182, 212, 0.1);
}

/* 空状态 */
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 40px;
  background: #ffffff;
}

.empty-icon {
  color: #cbd5e1;
  margin-bottom: 20px;
}

.empty-title {
  margin: 0 0 8px;
  font-size: 20px;
  font-weight: 700;
  color: #0f172a;
}

.empty-description {
  margin: 0;
  font-size: 14px;
  color: #64748b;
}

/* 历史记录表格容器 */
.history-table-container {
  background: #ffffff;
}

/* 表格样式 */
:deep(.history-table) {
  border: none;
}

:deep(.history-table .el-table__header-wrapper) {
  background: #f8fafc;
}

:deep(.history-table th.el-table__cell) {
  background: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  color: #475569;
  font-weight: 600;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  padding: 16px 12px;
}

:deep(.history-table td.el-table__cell) {
  border-bottom: 1px solid #f1f5f9;
  padding: 16px 12px;
}

:deep(.history-table tr:hover > td) {
  background: #f8fafc;
}

/* 翻译键样式 */
.key-text {
  font-weight: 600;
  color: #0f172a;
  font-family: 'Fira Code', monospace;
  font-size: 13px;
}

/* 操作标签 */
.operation-tag {
  border: none;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: 6px;
  font-size: 12px;
}

.operation-create {
  background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
  color: #059669;
}

.operation-update {
  background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
  color: #2563eb;
}

.operation-delete {
  background: linear-gradient(135deg, #ffe4e6 0%, #fecdd3 100%);
  color: #e11d48;
}

/* 值文本 */
.value-text {
  font-size: 13px;
  word-break: break-word;
}

.old-value {
  color: #64748b;
  font-style: italic;
}

.new-value {
  color: #0f172a;
  font-weight: 500;
}

.value-text.placeholder {
  color: #cbd5e1;
}

/* 用户信息 */
.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  justify-content: center;
}

.user-avatar {
  background: linear-gradient(135deg, #06b6d4 0%, #14b8a6 100%);
  color: white;
  font-weight: 600;
  font-size: 12px;
}

.user-name {
  font-size: 13px;
  color: #0f172a;
  font-weight: 500;
}

/* 时间文本 */
.time-text {
  font-size: 13px;
  color: #64748b;
  font-family: 'Fira Code', monospace;
}

/* 分页 */
.pagination-container {
  display: flex;
  justify-content: flex-end;
  padding: 20px 24px;
  background: #ffffff;
  border-top: 1px solid #f1f5f9;
}

:deep(.el-pagination) {
  font-weight: 500;
}

:deep(.el-pagination .el-pager li) {
  border-radius: 8px;
  margin: 0 2px;
}

:deep(.el-pagination .el-pager li.is-active) {
  background: linear-gradient(135deg, #06b6d4 0%, #14b8a6 100%);
  color: #ffffff;
}

:deep(.el-pagination button) {
  border-radius: 8px;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .filter-toolbar {
    flex-direction: column;
    align-items: stretch;
  }

  .filter-left {
    flex-direction: column;
  }

  .filter-input,
  .filter-select,
  .filter-date-picker {
    width: 100%;
  }

  .filter-right {
    display: flex;
    justify-content: flex-end;
  }

  .pagination-container {
    justify-content: center;
  }

  :deep(.el-pagination) {
    flex-wrap: wrap;
    justify-content: center;
  }
}
</style>
