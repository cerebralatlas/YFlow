package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"
	"yflow/internal/config"
	"yflow/internal/domain"
)

// LibreTranslateService LibreTranslate 机器翻译服务实现
type LibreTranslateService struct {
	cfg *config.LibreTranslateConfig
}

// NewLibreTranslateService 创建 LibreTranslate 服务实例
func NewLibreTranslateService(cfg *config.LibreTranslateConfig) *LibreTranslateService {
	return &LibreTranslateService{
		cfg: cfg,
	}
}

// Translate 单条翻译
func (s *LibreTranslateService) Translate(ctx context.Context, text, sourceLang, targetLang string) (*domain.MachineTranslationResult, error) {
	if text == "" {
		return nil, fmt.Errorf("text cannot be empty")
	}

	// 处理自动检测源语言
	if sourceLang == "auto" {
		sourceLang = "auto"
	}

	url := fmt.Sprintf("%s/translate", s.cfg.URL)

	payload := map[string]string{
		"q":      text,
		"source": sourceLang,
		"target": targetLang,
		"format": "text",
	}

	if s.cfg.APIKey != "" {
		payload["api_key"] = s.cfg.APIKey
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to call translation API: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("translation API returned status %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		TranslatedText string `json:"translatedText"`
		DetectedLang   string `json:"detectedLanguageSource,omitempty"`
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &domain.MachineTranslationResult{
		TranslatedText:     result.TranslatedText,
		DetectedSourceLang: result.DetectedLang,
	}, nil
}

// TranslateBatch 批量翻译
func (s *LibreTranslateService) TranslateBatch(ctx context.Context, texts []string, sourceLang, targetLang string) ([]*domain.MachineTranslationResult, error) {
	if len(texts) == 0 {
		return []*domain.MachineTranslationResult{}, nil
	}

	results := make([]*domain.MachineTranslationResult, 0, len(texts))
	errors := make([]error, 0)

	// 限制批量大小
	batchSize := 10
	for i := 0; i < len(texts); i += batchSize {
		end := i + batchSize
		if end > len(texts) {
			end = len(texts)
		}

		batch := texts[i:end]
		for _, text := range batch {
			result, err := s.Translate(ctx, text, sourceLang, targetLang)
			if err != nil {
				errors = append(errors, fmt.Errorf("failed to translate '%s': %w", text, err))
				results = append(results, nil)
			} else {
				results = append(results, result)
			}
		}

		// 避免请求过快
		time.Sleep(100 * time.Millisecond)
	}

	return results, nil
}

// GetSupportedLanguages 获取支持的语言列表
func (s *LibreTranslateService) GetSupportedLanguages(ctx context.Context) ([]domain.MachineTranslationLanguage, error) {
	// API v2: /languages, API v1: /api/language
	url := fmt.Sprintf("%s/languages", s.cfg.URL)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to call languages API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("languages API returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var languages []domain.MachineTranslationLanguage
	if err := json.Unmarshal(body, &languages); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return languages, nil
}

// IsAvailable 检查服务是否可用
func (s *LibreTranslateService) IsAvailable(ctx context.Context) bool {
	// 使用 /languages 端点进行健康检查
	url := fmt.Sprintf("%s/languages", s.cfg.URL)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		log.Printf("LibreTranslate health check failed: %v", err)
		return false
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("LibreTranslate health check failed: %v", err)
		return false
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK
}

// LanguageCodeMapping YFlow 语言代码到 LibreTranslate 语言代码的映射
// YFlow 使用如 "zh", "zh_TW", "en_US" 等代码
// LibreTranslate 使用如 "zh", "zh-TW", "en" 等代码
var LanguageCodeMapping = map[string]string{
	// 简体/繁体中文
	"zh":     "zh",
	"zh_CN":  "zh",
	"zh_TW":  "zh-TW",
	"zh_HK":  "zh-TW",
	"zh_SG":  "zh",
	"zh_MO":  "zh-TW",

	// 英语变体
	"en":     "en",
	"en_US":  "en",
	"en_GB":  "en",
	"en_CA":  "en",
	"en_AU":  "en",

	// 西班牙语
	"es":     "es",
	"es_ES":  "es",
	"es_MX":  "es",

	// 法语
	"fr":     "fr",
	"fr_FR":  "fr",
	"fr_CA":  "fr",

	// 葡萄牙语
	"pt":     "pt",
	"pt_PT":  "pt",
	"pt_BR":  "pt",

	// 德语
	"de":     "de",
	"de_DE":  "de",
	"de_AT":  "de",
	"de_CH":  "de",

	// 日语
	"ja":     "ja",
	"ja_JP":  "ja",

	// 韩语
	"ko":     "ko",
	"ko_KR":  "ko",

	// 其他语言直接映射
	"ar":     "ar",
	"ru":     "ru",
	"it":     "it",
	"nl":     "nl",
	"pl":     "pl",
	"tr":     "tr",
	"vi":     "vi",
	"th":     "th",
	"hi":     "hi",
	"id":     "id",
	"ms":     "ms",
	"uk":     "uk",
	"cs":     "cs",
	"el":     "el",
	"he":     "he",
	"ro":     "ro",
	"hu":     "hu",
	"sv":     "sv",
	"da":     "da",
	"fi":     "fi",
	"no":     "no",
	"sk":     "sk",
	"bg":     "bg",
	"hr":     "hr",
	"lt":     "lt",
	"lv":     "lv",
	"sl":     "sl",
	"et":     "et",
	"ca":     "ca",
	"tl":     "tl",
	"bn":     "bn",
	"sr":     "sr",
	"fa":     "fa",
	"ur":     "ur",
}

// ToLibreTranslateCode 将 YFlow 语言代码转换为 LibreTranslate 代码
func ToLibreTranslateCode(yflowCode string) string {
	if mapped, ok := LanguageCodeMapping[yflowCode]; ok {
		return mapped
	}
	// 如果没有映射，尝试直接使用（可能已经兼容）
	return yflowCode
}

// FromLibreTranslateCode 将 LibreTranslate 代码转换为 YFlow 代码
// LibreTranslate 使用如 "zh", "zh-Hant", "en" 等代码
// YFlow 使用如 "zh_CN", "zh_TW", "en" 等代码
func FromLibreTranslateCode(libreCode string) string {
	reverseMapping := map[string]string{
		// 中文（LibreTranslate 可能返回 zh, zh-Hans, zh-Hant）
		"zh":      "zh_CN", // 默认使用 zh_CN
		"zh-Hans": "zh_CN",
		"zh-Hant": "zh_TW",
		"zh-TW":   "zh_TW",
		"zh-HK":   "zh_HK",
		"zh-SG":   "zh_SG",
		"zh-MO":   "zh_MO",

		// 英语变体
		"en":     "en",
		"en-US":  "en_US",
		"en-GB":  "en_GB",
		"en-CA":  "en_CA",
		"en-AU":  "en_AU",

		// 西班牙语
		"es":     "es",
		"es-ES":  "es_ES",
		"es-MX":  "es_MX",

		// 法语
		"fr":     "fr",
		"fr-FR":  "fr_FR",
		"fr-CA":  "fr_CA",

		// 葡萄牙语
		"pt":     "pt",
		"pt-PT":  "pt_PT",
		"pt-BR":  "pt_BR",

		// 德语
		"de":     "de",
		"de-DE":  "de_DE",
		"de-AT":  "de_AT",
		"de-CH":  "de_CH",

		// 日语
		"ja":     "ja",
		"ja-JP":  "ja_JP",

		// 韩语
		"ko":     "ko",
		"ko-KR":  "ko_KR",

		// 其他语言直接返回
		"ar":     "ar",
		"ru":     "ru",
		"it":     "it",
		"nl":     "nl",
		"pl":     "pl",
		"tr":     "tr",
		"vi":     "vi",
		"th":     "th",
		"hi":     "hi",
		"id":     "id",
		"ms":     "ms",
		"uk":     "uk",
		"cs":     "cs",
		"el":     "el",
		"he":     "he",
		"ro":     "ro",
		"hu":     "hu",
		"sv":     "sv",
		"da":     "da",
		"fi":     "fi",
		"no":     "no",
		"sk":     "sk",
		"bg":     "bg",
		"hr":     "hr",
		"lt":     "lt",
		"lv":     "lv",
		"sl":     "sl",
		"et":     "et",
		"ca":     "ca",
		"tl":     "tl",
		"bn":     "bn",
		"sr":     "sr",
		"fa":     "fa",
		"ur":     "ur",
	}
	if mapped, ok := reverseMapping[libreCode]; ok {
		return mapped
	}
	// 如果没有映射，尝试提取基础语言代码
	if len(libreCode) >= 2 {
		baseCode := libreCode[:2]
		if baseCode == "zh" {
			return "zh_CN"
		}
		return baseCode
	}
	return libreCode
}
