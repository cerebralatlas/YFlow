<template>
  <el-dialog
    v-model="visible"
    title="自动填充翻译"
    width="500px"
    :close-on-click-modal="false"
    destroy-on-close
    @close="handleClose"
  >
    <div class="auto-fill-info">
      <el-icon><InfoFilled /></el-icon>
      <span>自动将项目的默认语言翻译填充到目标语言的所有缺失翻译</span>
    </div>

    <el-form :model="autoFillForm" label-width="100px">
      <el-form-item label="源语言">
        <el-select v-model="autoFillForm.sourceLang" placeholder="选择源语言" class="full-width">
          <el-option
            v-for="lang in languages"
            :key="lang.code"
            :label="lang.name"
            :value="lang.code"
          />
        </el-select>
      </el-form-item>
      <el-form-item label="目标语言" required>
        <el-select v-model="autoFillForm.targetLang" placeholder="选择目标语言" class="full-width">
          <el-option
            v-for="lang in languages"
            :key="lang.code"
            :label="lang.name"
            :value="lang.code"
          />
        </el-select>
      </el-form-item>
    </el-form>

    <div v-if="autoFillResult" class="auto-fill-result">
      <el-divider content-position="left">填充结果</el-divider>
      <div class="results-summary">
        <el-tag type="success">成功: {{ autoFillResult.success_count }}</el-tag>
        <el-tag type="danger" v-if="autoFillResult.failed_count > 0">失败: {{ autoFillResult.failed_count }}</el-tag>
      </div>
    </div>

    <template #footer>
      <span class="dialog-footer">
        <el-button @click="handleClose">取消</el-button>
        <el-button type="primary" @click="handleAutoFill" :loading="loading">
          开始填充
        </el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { InfoFilled } from '@element-plus/icons-vue'
import {
  autoFillLanguage,
  getMachineTranslateLanguages,
} from '@/services/translation'
import type { MachineTranslationLanguage } from '@/types/translation'

const props = defineProps<{
  modelValue: boolean
  showTabs?: boolean
  projectId?: number
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'filled'): void
}>()

// State
const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value),
})

const loading = ref(false)
const languages = ref<MachineTranslationLanguage[]>([])
const autoFillResult = ref<{ success_count: number; failed_count: number } | null>(null)

// Form
const autoFillForm = ref({
  sourceLang: 'en',
  targetLang: '',
})

// Watch for dialog open
watch(visible, async (newVal) => {
  if (newVal) {
    await loadLanguages()
  }
})

// Load languages
const loadLanguages = async () => {
  try {
    languages.value = await getMachineTranslateLanguages()
  } catch (err: any) {
    console.error('Failed to load languages:', err)
    // Use default languages as fallback
    languages.value = [
      { code: 'en', name: '英语' },
      { code: 'zh', name: '中文' },
      { code: 'ja', name: '日语' },
      { code: 'ko', name: '韩语' },
      { code: 'fr', name: '法语' },
      { code: 'de', name: '德语' },
      { code: 'es', name: '西班牙语' },
      { code: 'pt', name: '葡萄牙语' },
      { code: 'ru', name: '俄语' },
      { code: 'ar', name: '阿拉伯语' },
    ]
  }
}

// Auto-fill language
const handleAutoFill = async () => {
  if (!props.projectId) {
    ElMessage.error('未指定项目')
    return
  }
  if (!autoFillForm.value.targetLang) {
    ElMessage.warning('请选择目标语言')
    return
  }

  loading.value = true
  try {
    const result = await autoFillLanguage(props.projectId, {
      source_lang: autoFillForm.value.sourceLang,
      target_lang: autoFillForm.value.targetLang,
    })
    autoFillResult.value = result
    ElMessage.success(`自动填充完成，成功 ${result.success_count}/${result.total}`)
    if (result.success_count > 0) {
      emit('filled')
    }
  } catch (err: any) {
    ElMessage.error(err.message || '自动填充失败，请稍后重试')
    console.error('Auto-fill error:', err)
  } finally {
    loading.value = false
  }
}

// Close dialog
const handleClose = () => {
  visible.value = false
  autoFillResult.value = null
}
</script>

<style scoped>
.full-width {
  width: 100%;
}

.auto-fill-info {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background: #ecf5ff;
  border-radius: 4px;
  margin-bottom: 20px;
  color: #409eff;
  font-size: 14px;
}

.auto-fill-result {
  margin-top: 20px;
}

.results-summary {
  display: flex;
  gap: 10px;
}
</style>
