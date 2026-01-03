import api from './api'
import type { Language, CreateLanguageRequest } from '@/types/translation'

/**
 * 获取所有语言列表
 */
export const getLanguages = async (): Promise<Language[]> => {
  return api.get('/languages')
}

/**
 * 创建新语言
 */
export const createLanguage = async (data: CreateLanguageRequest): Promise<Language> => {
  return api.post('/languages', data)
}

/**
 * 更新语言
 */
export const updateLanguage = async (id: number, data: CreateLanguageRequest): Promise<Language> => {
  return api.put(`/languages/${id}`, data)
}

/**
 * 删除语言
 */
export const deleteLanguage = async (id: number): Promise<void> => {
  return api.delete(`/languages/${id}`)
}
