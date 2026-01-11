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
  TranslationHistoryQueryParams,
  TranslationHistoryListResponse,
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

// ==================== Translation History APIs ====================

/**
 * 获取单个翻译的历史记录
 */
export const getTranslationHistory = async (
  translationId: number,
  params?: TranslationHistoryQueryParams
): Promise<TranslationHistoryListResponse> => {
  const query: Record<string, any> = {
    page: params?.page || 1,
    page_size: params?.page_size || 10,
  }
  if (params?.operation) query.operation = params.operation
  if (params?.start_date) query.start_date = params.start_date
  if (params?.end_date) query.end_date = params.end_date

  const response = await api.get(`/translations/${translationId}/history`, { params: query }) as {
    data: TranslationHistoryListResponse
    meta: any
  }
  return response.data
}

/**
 * 获取项目的翻译历史
 */
export const getProjectTranslationHistory = async (
  projectId: number,
  params?: TranslationHistoryQueryParams
): Promise<TranslationHistoryListResponse> => {
  const query: Record<string, any> = {
    page: params?.page || 1,
    page_size: params?.page_size || 10,
  }
  if (params?.operation) query.operation = params.operation
  if (params?.keyword) query.keyword = params.keyword
  if (params?.start_date) query.start_date = params.start_date
  if (params?.end_date) query.end_date = params.end_date

  const response = await api.get(`/projects/${projectId}/translation-history`, { params: query }) as {
    data: TranslationHistoryListResponse
    meta: any
  }
  return response.data
}

/**
 * 获取用户的翻译操作历史
 */
export const getUserTranslationHistory = async (
  userId: number,
  params?: TranslationHistoryQueryParams
): Promise<TranslationHistoryListResponse> => {
  const query: Record<string, any> = {
    page: params?.page || 1,
    page_size: params?.page_size || 10,
  }
  if (params?.operation) query.operation = params.operation
  if (params?.start_date) query.start_date = params.start_date
  if (params?.end_date) query.end_date = params.end_date

  const response = await api.get(`/users/${userId}/translation-history`, { params: query }) as {
    data: TranslationHistoryListResponse
    meta: any
  }
  return response.data
}
