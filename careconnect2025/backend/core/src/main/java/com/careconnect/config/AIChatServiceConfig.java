package com.careconnect.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import com.careconnect.service.security.SecurityAuditService;

@Configuration
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
public class AIChatServiceConfig {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(AIChatServiceConfig.class);
    private static final String MASKED_KEY_DISPLAY = "****";

    @Autowired
    private SecurityAuditService securityAuditService;

    public AIChatServiceConfig() {
        log.info("AIChatServiceConfig initialized - DeepSeek ChatModel configuration ACTIVE");
    }

    @Value("${deepseek.api.key:}")
    private String deepSeekApiKey;

    @Value("${deepseek.api.url:https://api.deepseek.com/v1}")
    private String deepSeekApiUrl;

    @Value("${ai.model.provider:deepseek}")
    private String modelProvider;
    
    // LangChain4j ChatModel for LangChainGovernanceService
    @Bean
    public ChatModel chatModel() {
        log.info("Creating LangChain4j ChatModel bean with DeepSeek configuration");

        // Validate required configuration
        validateConfiguration();

        // Log configuration without exposing sensitive data
        log.info("  - API Key: {}", MASKED_KEY_DISPLAY);
        log.info("  - Base URL: {}", deepSeekApiUrl);
        log.info("  - Model: deepseek-chat");

        try {
            return OpenAiChatModel.builder()
                    .apiKey(deepSeekApiKey)
                    .baseUrl(deepSeekApiUrl)
                    .modelName("deepseek-chat")
                    .build();
        } catch (Exception e) {
            log.error("Failed to create DeepSeek ChatModel: {}", e.getMessage());
            throw new IllegalStateException("DeepSeek configuration failed", e);
        }
    }

    
    private void validateConfiguration() {
        if (!StringUtils.hasText(deepSeekApiKey)) {
            String error = "DeepSeek API key is required but not configured";
            securityAuditService.logConfigurationValidationError("DeepSeek", "API_KEY", error);
            throw new IllegalStateException(error);
        }

        if (!StringUtils.hasText(deepSeekApiUrl)) {
            String error = "DeepSeek API URL is required but not configured";
            securityAuditService.logConfigurationValidationError("DeepSeek", "API_URL", error);
            throw new IllegalStateException(error);
        }

        // Validate URL format
        if (!deepSeekApiUrl.startsWith("https://")) {
            String warning = "DeepSeek API URL should use HTTPS for security: " + deepSeekApiUrl;
            log.warn(warning);
            securityAuditService.logConfigurationValidationError("DeepSeek", "API_URL_SECURITY", warning);
        }

        // Basic API key format validation (adjust based on DeepSeek's actual format)
        if (deepSeekApiKey.length() < 20) {
            String warning = "API key appears to be too short, please verify configuration";
            log.warn(warning);
        }
    }
}
