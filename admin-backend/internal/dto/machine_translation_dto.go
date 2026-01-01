package dto

// AutoFillLanguageRequest 自动填充语言请求
type AutoFillLanguageRequest struct {
	TargetLang string `json:"target_lang" binding:"required"`
	SourceLang string `json:"source_lang"` // 可选，默认为默认语言
}

// AutoFillLanguageResponse 自动填充语言响应
type AutoFillLanguageResponse struct {
	Total        int    `json:"total"`
	SuccessCount int    `json:"success_count"`
	FailedCount  int    `json:"failed_count"`
	Message      string `json:"message"`
}
