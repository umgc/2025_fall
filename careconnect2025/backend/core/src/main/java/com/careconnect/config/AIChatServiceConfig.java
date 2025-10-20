
package com.careconnect.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import dev.langchain4j.model.chat.ChatModel;
import dev.langchain4j.model.openai.OpenAiChatModel;

@Configuration
@ConditionalOnProperty(name = "careconnect.openai.enabled", havingValue = "true", matchIfMissing = true)
public class AIChatServiceConfig {


    @Value("${openai.api.key:}")
    private String openAiApiKey;

    @Value("${openai.model.name:gpt-4}")
    private String openAiModelName;

    @Bean
    public ChatModel chatModel() {
        return OpenAiChatModel.builder()
                .apiKey(openAiApiKey)
                .modelName(openAiModelName)
                .build();
    }
}
