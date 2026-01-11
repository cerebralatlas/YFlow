// Translation data models
export interface Translation {
  id: number
  project_id: number
  language_id: number
  key_name: string
  value: string
  context?: string
  status: 'active' | 'deprecated'
  created_at: string
  updated_at: string
}

export interface Language {
  id: number
  code: string
  name: string
  is_default: boolean
  status: 'active' | 'inactive'
  created_at: string
  updated_at: string
}

// Translation matrix for table display
export interface TranslationMatrixRow {
  key_name: string
  context?: string
  translations: Record<string, TranslationCell>
}

export interface TranslationCell {
  id?: number
  language_id: number
  value: string
  status?: 'active' | 'deprecated'
  updated_at?: string
}

export interface TranslationMatrix {
  languages: Language[]
  rows: TranslationMatrixRow[]
  total_count: number
  page: number
  page_size: number
  total_pages: number
}

// API request models
export interface CreateTranslationRequest {
  project_id: number
  language_id: number
  key_name: string
  value: string
  context?: string
}

export interface BatchTranslationRequest {
  project_id: number
  key_name: string
  context?: string
  translations: Record<string, string> // language_code -> value
}

export interface CreateLanguageRequest {
  code: string
  name: string
  is_default?: boolean
}

export interface ImportTranslationsData {
  [languageCode: string]: {
    [key: string]: string
  }
}

// ==================== Machine Translation ====================

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

// ==================== Translation History ====================

export interface TranslationHistory {
  id: number
  translation_id?: number
  project_id: number
  key_name: string
  language_id: number
  old_value?: string
  new_value?: string
  operation: 'create' | 'update' | 'delete'
  operated_by: number
  operated_at: string
  metadata?: string
}

export interface TranslationHistoryQueryParams {
  page?: number
  page_size?: number
  operation?: string
  keyword?: string
  start_date?: string
  end_date?: string
}

export interface TranslationHistoryListResponse {
  histories: TranslationHistory[]
  meta: {
    page: number
    page_size: number
    total_count: number
    total_pages: number
  }
}
