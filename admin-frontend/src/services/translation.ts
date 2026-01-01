import api from './api'
import type {
  Translation,
  TranslationMatrix,
  CreateTranslationRequest,
  BatchTranslationRequest,
  ImportTranslationsData,
} from '@/types/translation'

// Machine Translation Types
export interface AutoFillLanguageRequest {
  target_lang: string
  source_lang?: string
}

export interface AutoFillLanguageResponse {
  total: number
  success_count: number
  failed_count: number
  message: string
}

export interface MachineTranslationLanguage {
  code: string
  name: string
}

// Machine Translation APIs

/**
 * 自动填充语言翻译
 */
export const autoFillLanguage = async (
  projectId: number,
  data: AutoFillLanguageRequest
): Promise<AutoFillLanguageResponse> => {
  const response = await api.post(`/projects/${projectId}/auto-fill-language`, data)
  return response as unknown as AutoFillLanguageResponse
}

/**
 * 获取机器翻译支持的语言列表
 */
export const getMachineTranslateLanguages = async (): Promise<MachineTranslationLanguage[]> => {
  const response = await api.get('/translations/machine-translate/languages')
  return response as unknown as MachineTranslationLanguage[]
}

/**
 * 检查机器翻译服务健康状态
 */
export const checkMachineTranslateHealth = async (): Promise<{ available: boolean }> => {
  const response = await api.get('/translations/machine-translate/health')
  return response as unknown as { available: boolean }
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

  const response = await api.get(`/translations/matrix/by-project/${projectId}`, { params })
  return response as unknown as TranslationMatrix
}

/**
 * 获取项目的所有翻译（分页）
 */
export const getProjectTranslations = async (
  projectId: number,
  page: number = 1,
  pageSize: number = 20
): Promise<{ data: Translation[]; meta: any }> => {
  const response = await api.get(`/translations/by-project/${projectId}`, {
    params: { page, page_size: pageSize },
  })
  return response as unknown as { data: Translation[]; meta: any }
}

/**
 * 获取单个翻译详情
 */
export const getTranslation = async (id: number): Promise<Translation> => {
  const response = await api.get(`/translations/${id}`)
  return response as unknown as Translation
}

/**
 * 创建翻译
 */
export const createTranslation = async (data: CreateTranslationRequest): Promise<Translation> => {
  const response = await api.post('/translations', data)
  return response as unknown as Translation
}

/**
 * 更新翻译
 */
export const updateTranslation = async (
  id: number,
  data: CreateTranslationRequest
): Promise<Translation> => {
  const response = await api.put(`/translations/${id}`, data)
  return response as unknown as Translation
}

/**
 * 删除翻译
 */
export const deleteTranslation = async (id: number): Promise<void> => {
  await api.delete(`/translations/${id}`)
}

/**
 * 批量创建翻译
 */
export const batchCreateTranslations = async (data: BatchTranslationRequest): Promise<void> => {
  await api.post('/translations/batch', data)
}

/**
 * 批量删除翻译
 */
export const batchDeleteTranslations = async (ids: number[]): Promise<void> => {
  await api.post('/translations/batch-delete', ids)
}

/**
 * 导出项目翻译
 */
export const exportTranslations = async (projectId: number): Promise<any> => {
  const response = await api.get(`/exports/project/${projectId}`)
  return response
}

/**
 * 导入项目翻译
 */
export const importTranslations = async (
  projectId: number,
  data: ImportTranslationsData,
  format: string = 'json'
): Promise<void> => {
  await api.post(`/imports/project/${projectId}`, data, {
    params: { format },
  })
}
