import api from './api'
import type {
  Translation,
  TranslationMatrix,
  CreateTranslationRequest,
  BatchTranslationRequest,
  ImportTranslationsData,
  AutoFillLanguageRequest,
  AutoFillLanguageResponse,
  MachineTranslationLanguage,
} from '@/types/translation'

// Machine Translation APIs

/**
 * 自动填充语言翻译
 */
export const autoFillLanguage = async (
  projectId: number,
  data: AutoFillLanguageRequest
): Promise<AutoFillLanguageResponse> => {
  return api.post(`/projects/${projectId}/auto-fill-language`, data)
}

/**
 * 获取机器翻译支持的语言列表
 */
export const getMachineTranslateLanguages = async (): Promise<MachineTranslationLanguage[]> => {
  return api.get('/translations/machine-translate/languages')
}

/**
 * 检查机器翻译服务健康状态
 */
export const checkMachineTranslateHealth = async (): Promise<{ available: boolean }> => {
  return api.get('/translations/machine-translate/health')
}

/**
 * 获取翻译矩阵（用于表格展示）
 */
export const getTranslationMatrix = async (
  projectId: number,
  page: number = 1,
  pageSize: number = 20,
  keyword?: string
): Promise<TranslationMatrix> => {
  const params: Record<string, any> = {
    page,
    page_size: pageSize,
  }
  if (keyword) {
    params.keyword = keyword
  }

  return api.get(`/translations/matrix/by-project/${projectId}`, { params })
}

/**
 * 获取项目的所有翻译（分页）
 */
export const getProjectTranslations = async (
  projectId: number,
  page: number = 1,
  pageSize: number = 20
): Promise<{ data: Translation[]; meta: any }> => {
  return api.get(`/translations/by-project/${projectId}`, {
    params: { page, page_size: pageSize },
  })
}

/**
 * 获取单个翻译详情
 */
export const getTranslation = async (id: number): Promise<Translation> => {
  return api.get(`/translations/${id}`)
}

/**
 * 创建翻译
 */
export const createTranslation = async (data: CreateTranslationRequest): Promise<Translation> => {
  return api.post('/translations', data)
}

/**
 * 更新翻译
 */
export const updateTranslation = async (
  id: number,
  data: CreateTranslationRequest
): Promise<Translation> => {
  return api.put(`/translations/${id}`, data)
}

/**
 * 删除翻译
 */
export const deleteTranslation = async (id: number): Promise<void> => {
  return api.delete(`/translations/${id}`)
}

/**
 * 批量创建翻译
 */
export const batchCreateTranslations = async (data: BatchTranslationRequest): Promise<void> => {
  return api.post('/translations/batch', data)
}

/**
 * 批量删除翻译
 */
export const batchDeleteTranslations = async (ids: number[]): Promise<void> => {
  return api.post('/translations/batch-delete', ids)
}

/**
 * 导出项目翻译
 */
export const exportTranslations = async (projectId: number): Promise<any> => {
  return api.get(`/exports/project/${projectId}`)
}

/**
 * 导入项目翻译
 */
export const importTranslations = async (
  projectId: number,
  data: ImportTranslationsData,
  format: string = 'json'
): Promise<void> => {
  return api.post(`/imports/project/${projectId}`, data, {
    params: { format },
  })
}
