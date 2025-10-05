
package com.careconnect.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.openai.OpenAiChatModel;

@Configuration
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = false)
public class AIChatServiceConfig {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(AIChatServiceConfig.class);

    public AIChatServiceConfig() {
        log.info("🔧 AIChatServiceConfig initialized - DeepSeek ChatModel configuration ACTIVE");
    }

    @Value("${deepseek.api.key:}")
    private String deepSeekApiKey;

    @Value("${deepseek.api.url:https://api.deepseek.com/v1}")
    private String deepSeekApiUrl;

    @Value("${ai.model.provider:deepseek}")
    private String modelProvider;

    @Bean
    public ChatModel chatModel() {
        log.info("🚀 Creating ChatModel bean with DeepSeek configuration:");
        log.info("  - API Key: {}...", deepSeekApiKey.substring(0, Math.min(10, deepSeekApiKey.length())));
        log.info("  - Base URL: {}", deepSeekApiUrl);
        log.info("  - Model: deepseek-chat");

        try {
            return OpenAiChatModel.builder()
                    .apiKey(deepSeekApiKey)
                    .baseUrl(deepSeekApiUrl)
                    .modelName("deepseek-chat")
                    .build();
        } catch (Exception e) {
            log.warn("DeepSeek configuration failed, this may be due to insufficient balance: {}", e.getMessage());
            throw e;
        }
    }
}
