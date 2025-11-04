package com.careconnect.config;

import com.careconnect.service.security.SecurityAuditService;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

@Configuration
@ConditionalOnProperty(name = "careconnect.ai.enabled", havingValue = "true", matchIfMissing = true)
public class AIChatServiceConfig {

    private static final Logger log = LoggerFactory.getLogger(AIChatServiceConfig.class);
    private static final String MASKED_KEY_DISPLAY = "****";

    private final SecurityAuditService securityAuditService;

    // Generic, provider-agnostic properties
    @Value("${careconnect.ai.provider:openai}")           // e.g., openai, deepseek, mistral
    private String provider;

    @Value("${careconnect.ai.api.key:}")
    private String apiKey;

    @Value("${careconnect.ai.api.url:https://api.openai.com/v1}")
    private String apiUrl;

    @Value("${careconnect.ai.model.name:gpt-4o-mini}")
    private String modelName;

    @Value("${careconnect.ai.model.temperature:1.0}")
    private double temperature;

    public AIChatServiceConfig(SecurityAuditService securityAuditService) {
        this.securityAuditService = securityAuditService;
        log.info("AIChatServiceConfig initialized. AI ChatModel configuration is active.");
    }

    @Bean
    public ChatModel chatModel() {
        log.info("Creating LangChain4j ChatModel bean for provider {}", provider);
        validateConfiguration();

        // Log config without secrets
        log.info("  - Provider: {}", provider);
        log.info("  - API Key: {}", MASKED_KEY_DISPLAY);
        log.info("  - Base URL: {}", apiUrl);
        log.info("  - Model: {}", modelName);
        log.info("  - Temperature: {}", temperature);

        try {
            // Any OpenAI-spec provider works by swapping baseUrl and apiKey
            return OpenAiChatModel.builder()
                    .apiKey(apiKey)
                    .baseUrl(apiUrl)
                    .modelName(modelName)
                    .temperature(temperature)
                    .build();
        } catch (Exception e) {
            log.error("Failed to create ChatModel: {}", e.getMessage());
            throw new IllegalStateException("AI configuration failed", e);
        }
    }

    private void validateConfiguration() {
        // API key present
        if (!StringUtils.hasText(apiKey)) {
            String error = "API key is required but not configured";
            securityAuditService.logConfigurationValidationError(provider, "API_KEY", error);
            throw new IllegalStateException(error);
        }

        // URL present
        if (!StringUtils.hasText(apiUrl)) {
            String error = "API URL is required but not configured";
            securityAuditService.logConfigurationValidationError(provider, "API_URL", error);
            throw new IllegalStateException(error);
        }

        // URL must be HTTPS
        if (!apiUrl.startsWith("https://")) {
            String warning = "API URL should use HTTPS for security: " + apiUrl;
            log.warn(warning);
            securityAuditService.logConfigurationValidationError(provider, "API_URL_SECURITY", warning);
        }

        // Basic key length sanity check
        if (apiKey.length() < 20) {
            String warning = "API key appears to be too short. Please verify configuration";
            log.warn(warning);
        }

        // Temperature sanity check
        if (temperature < 0.0 || temperature > 2.0) {
            String warning = "Temperature is out of expected range [0.0, 2.0]: " + temperature;
            log.warn(warning);
        }
    }
}
