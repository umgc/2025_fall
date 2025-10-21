package com.careconnect.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.core.JsonProcessingException;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

//Service configured to hit DeepSeek API v3 via OpenRouter for unlimited free tier 
@Slf4j
@Service
@ConditionalOnProperty(name = "careconnect.openrouter.enabled", havingValue = "true", matchIfMissing = true)
public class DeepSeekService {

    @Value("${openrouter.api.key:}")
    private String apiKey;

    @Value("${openrouter.api.url:https://openrouter.ai/api/v1}")
    private String apiUrl;

    public DeepSeekService() {
    }

    public DeepSeekResponse sendChatRequest(DeepSeekChatRequest request) {
        if (apiKey == null || apiKey.trim().isEmpty()) {
            throw new IllegalStateException("DeepSeek API key is not configured");
        }

        log.info("Sending chat request to DeepSeek with model: {}", request.getModel());

        String endpoint = apiUrl;
        if (endpoint == null || endpoint.trim().isEmpty()) {
            endpoint = "https://api.deepseek.com/v1";
        }
        if (!endpoint.endsWith("/")) {
            endpoint = endpoint + "/";
        }
        String url = endpoint + "chat/completions";

    RestTemplate restTemplate = new RestTemplate();
    ObjectMapper mapper = new ObjectMapper();
    mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        try {
            String body = mapper.writeValueAsString(request);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);

            HttpEntity<String> entity = new HttpEntity<>(body, headers);

            ResponseEntity<String> resp = restTemplate.postForEntity(url, entity, String.class);

            if (resp.getStatusCode().is2xxSuccessful()) {
                String respBody = resp.getBody();

                if (respBody == null || respBody.trim().isEmpty()) {
                    throw new DeepSeekException("DeepSeek returned empty response", null);
                }
                DeepSeekResponse deepSeekResponse = mapper.readValue(respBody, DeepSeekResponse.class);
                return deepSeekResponse;
            } else {
                String respBody = resp.getBody();
                log.error("DeepSeek API returned non-200 status: {} body={}", resp.getStatusCode().value(), respBody);
                throw new DeepSeekException("DeepSeek API error: status=" + resp.getStatusCode().value() + " body=" + respBody, null);
            }
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize/deserialize DeepSeek payload/response", e);
            throw new DeepSeekException("JSON processing error communicating with DeepSeek", e);
        } catch (RestClientException e) {
            log.error("HTTP error when calling DeepSeek API", e);
            throw new DeepSeekException("HTTP error communicating with DeepSeek", e);
        } catch (Exception e) {
            log.error("Unexpected error when calling DeepSeek API", e);
            throw new DeepSeekException("Unexpected error communicating with DeepSeek", e);
        }
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class DeepSeekChatRequest {
        private String model;
        private List<Message> messages;
        private Double temperature;
        private Integer maxTokens;
        private Boolean stream = false;

        public DeepSeekChatRequest() {
        }

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

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Message {
        private String role;
        private String content;

        public Message() {
        }

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

    @JsonIgnoreProperties(ignoreUnknown = true)
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

    @JsonIgnoreProperties(ignoreUnknown = true)
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

    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Usage {
        private Integer promptTokens;
        private Integer completionTokens;
        private Integer totalTokens;
        private Integer promptCacheHitTokens;
        private Integer promptCacheMissTokens;

        public Integer getPromptCacheHitTokens() {
            return promptCacheHitTokens;
        }
        public void setPromptCacheHitTokens(Integer promptCacheHitTokens) {
            this.promptCacheHitTokens = promptCacheHitTokens;
        }

        public Integer getPromptCacheMissTokens() {
            return promptCacheMissTokens;
        }
        
        public void setPromptCacheMissTokens(Integer promptCacheMissTokens) {
            this.promptCacheMissTokens = promptCacheMissTokens;
        }
       
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
