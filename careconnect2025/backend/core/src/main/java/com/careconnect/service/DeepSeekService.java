package com.careconnect.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

@Slf4j
@Service
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
public class DeepSeekService {

    @Value("${deepseek.api.key:}")
    private String apiKey;

    @Value("${deepseek.api.url:https://api.deepseek.com/v1}")
    private String apiUrl;

    private final org.springframework.web.client.RestTemplate restTemplate;

    public DeepSeekService() {
        this.restTemplate = new org.springframework.web.client.RestTemplate();
    }

    public DeepSeekResponse sendChatRequest(DeepSeekChatRequest request) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            throw new IllegalStateException("DeepSeek API key is not configured");
        }

        log.info("Sending chat request to DeepSeek with model: {}", request.getModel());

        try {
            // Use reusable RestTemplate instance for HTTP communication
            var headers = new org.springframework.http.HttpHeaders();
            headers.setContentType(org.springframework.http.MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            var entity = new org.springframework.http.HttpEntity<>(request, headers);
            var response = restTemplate.postForEntity(
                apiUrl + "/chat/completions",
                entity,
                DeepSeekResponse.class
            );

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                return response.getBody();
            } else {
                throw new DeepSeekException("DeepSeek API request failed with status: " + response.getStatusCode(), null);
            }
        } catch (Exception e) {
            log.error("Error calling DeepSeek API", e);
            throw new DeepSeekException("Failed to call DeepSeek API: " + e.getMessage(), e);
        }
    }

    // DTO Classes
    public static class DeepSeekChatRequest {
        private String model;
        private List<Message> messages;
        private Double temperature;
        private Integer maxTokens;
        private Boolean stream = false;

        public DeepSeekChatRequest(String model, List<Message> messages, Double temperature, Integer maxTokens) {
            this.model = model;
            this.messages = messages;
            this.temperature = temperature;
            this.maxTokens = maxTokens;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }

        public List<Message> getMessages() {
            return messages;
        }

        public void setMessages(List<Message> messages) {
            this.messages = messages;
        }

        public Double getTemperature() {
            return temperature;
        }

        public void setTemperature(Double temperature) {
            this.temperature = temperature;
        }

        public Integer getMaxTokens() {
            return maxTokens;
        }

        public void setMaxTokens(Integer maxTokens) {
            this.maxTokens = maxTokens;
        }

        public Boolean getStream() {
            return stream;
        }

        public void setStream(Boolean stream) {
            this.stream = stream;
        }
    }

    public static class Message {
        private String role;
        private String content;

        public Message(String role, String content) {
            this.role = role;
            this.content = content;
        }

        public String getRole() {
            return role;
        }

        public void setRole(String role) {
            this.role = role;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }
    }

    public static class DeepSeekResponse {
        private String id;
        private String object;
        private Long created;
        private String model;
        private List<Choice> choices;
        private Usage usage;

        public String getId() {
            return id;
        }

        public void setId(String id) {
            this.id = id;
        }

        public String getObject() {
            return object;
        }

        public void setObject(String object) {
            this.object = object;
        }

        public Long getCreated() {
            return created;
        }

        public void setCreated(Long created) {
            this.created = created;
        }

        public String getModel() {
            return model;
        }

        public void setModel(String model) {
            this.model = model;
        }

        public List<Choice> getChoices() {
            return choices;
        }

        public void setChoices(List<Choice> choices) {
            this.choices = choices;
        }

        public Usage getUsage() {
            return usage;
        }

        public void setUsage(Usage usage) {
            this.usage = usage;
        }
    }

    public static class Choice {
        private Integer index;
        private Message message;
        private String finishReason;

        public Integer getIndex() {
            return index;
        }

        public void setIndex(Integer index) {
            this.index = index;
        }

        public Message getMessage() {
            return message;
        }

        public void setMessage(Message message) {
            this.message = message;
        }

        public String getFinishReason() {
            return finishReason;
        }

        public void setFinishReason(String finishReason) {
            this.finishReason = finishReason;
        }
    }

    public static class Usage {
        private Integer promptTokens;
        private Integer completionTokens;
        private Integer totalTokens;

        public Integer getPromptTokens() {
            return promptTokens;
        }

        public void setPromptTokens(Integer promptTokens) {
            this.promptTokens = promptTokens;
        }

        public Integer getCompletionTokens() {
            return completionTokens;
        }

        public void setCompletionTokens(Integer completionTokens) {
            this.completionTokens = completionTokens;
        }

        public Integer getTotalTokens() {
            return totalTokens;
        }

        public void setTotalTokens(Integer totalTokens) {
            this.totalTokens = totalTokens;
        }
    }

    public static class DeepSeekException extends RuntimeException {
        public DeepSeekException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
