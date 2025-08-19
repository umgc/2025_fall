// File: apis/CailaApi.java
package com.focusedai.caila.apis;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class CailaApi {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    
    @Value("${openapi.api.key}")
    private String apiKey;
    
    @Value("${openapi.api.url}")
    private String apiUrl;
    
    @Value("${openapi.api.model}")
    private String model;
    
    /**
     * Generate content using the DeepSeek API
     */
    public String generateContent(String prompt) {
        return generateContent(prompt, null);
    }
    
    /**
     * Generate content with conversation history
     */
    public String generateContent(String prompt, List<Map<String, String>> conversationHistory) {
        try {
            log.debug("Generating content with prompt: {}", prompt.substring(0, Math.min(100, prompt.length())));
            
            List<Map<String, Object>> messages = buildMessageList(prompt, conversationHistory);
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", model);
            requestBody.put("messages", messages);
            requestBody.put("temperature", 0.7);
            requestBody.put("max_tokens", 2000);
            requestBody.put("stream", false);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            
            log.debug("Sending request to DeepSeek API: {}", apiUrl);
            ResponseEntity<String> response = restTemplate.postForEntity(apiUrl, request, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                return extractContentFromResponse(response.getBody());
            } else {
                throw new RuntimeException("API request failed with status: " + response.getStatusCode());
            }
            
        } catch (RestClientException e) {
            log.error("RestClient error when calling DeepSeek API", e);
            throw new RuntimeException("Failed to generate content - API communication error: " + e.getMessage());
        } catch (Exception e) {
            log.error("Unexpected error when generating content", e);
            throw new RuntimeException("Failed to generate content: " + e.getMessage());
        }
    }
    
    /**
     * Generate content with specific parameters
     */
    public String generateContentWithParameters(String prompt, double temperature, int maxTokens, 
                                              List<Map<String, String>> conversationHistory) {
        try {
            log.debug("Generating content with custom parameters - temp: {}, max_tokens: {}", temperature, maxTokens);
            
            List<Map<String, Object>> messages = buildMessageList(prompt, conversationHistory);
            
            Map<String, Object> requestBody = new HashMap<>();
            requestBody.put("model", model);
            requestBody.put("messages", messages);
            requestBody.put("temperature", temperature);
            requestBody.put("max_tokens", maxTokens);
            requestBody.put("stream", false);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(apiKey);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(apiUrl, request, String.class);

            if (response.getStatusCode().is2xxSuccessful()) {
                return extractContentFromResponse(response.getBody());
            } else {
                throw new RuntimeException("API request failed with status: " + response.getStatusCode());
            }
            
        } catch (Exception e) {
            log.error("Error generating content with parameters", e);
            throw new RuntimeException("Failed to generate content with parameters: " + e.getMessage());
        }
    }
    
    /**
     * Generate content for specific material types with optimized prompts
     */
    public String generateMaterialContent(String materialType, String prompt, String courseContext) {
        try {
            String enhancedPrompt = enhancePromptForMaterialType(materialType, prompt, courseContext);
            return generateContent(enhancedPrompt);
        } catch (Exception e) {
            log.error("Error generating material content for type: {}", materialType, e);
            throw new RuntimeException("Failed to generate " + materialType + " content: " + e.getMessage());
        }
    }
    
    /**
     * Test API connectivity
     */
    public boolean testConnection() {
        try {
            String testPrompt = "Hello, can you respond with 'API connection successful'?";
            String response = generateContent(testPrompt);
            return response != null && !response.trim().isEmpty();
        } catch (Exception e) {
            log.error("API connection test failed", e);
            return false;
        }
    }
    
    /**
     * Get API status and model information
     */
    public Map<String, Object> getApiStatus() {
        Map<String, Object> status = new HashMap<>();
        try {
            boolean isConnected = testConnection();
            status.put("connected", isConnected);
            status.put("apiUrl", apiUrl);
            status.put("model", model);
            status.put("timestamp", new Date().toString());
            
            if (isConnected) {
                status.put("status", "operational");
                status.put("message", "API is responding normally");
            } else {
                status.put("status", "error");
                status.put("message", "API connection failed");
            }
        } catch (Exception e) {
            status.put("connected", false);
            status.put("status", "error");
            status.put("message", "Error checking API status: " + e.getMessage());
        }
        return status;
    }
    
    // Private helper methods
    
    /**
     * Build message list for API request
     */
    private List<Map<String, Object>> buildMessageList(String prompt, List<Map<String, String>> conversationHistory) {
        List<Map<String, Object>> messages = new ArrayList<>();
        
        // Add conversation history if provided
        if (conversationHistory != null && !conversationHistory.isEmpty()) {
            for (Map<String, String> historyMessage : conversationHistory) {
                Map<String, Object> message = new HashMap<>();
                message.put("role", historyMessage.get("role"));
                message.put("content", historyMessage.get("content"));
                messages.add(message);
            }
        }
        
        // Add current user prompt
        Map<String, Object> userMessage = new HashMap<>();
        userMessage.put("role", "user");
        userMessage.put("content", prompt);
        messages.add(userMessage);
        
        return messages;
    }
    
    /**
     * Extract content from API response
     */
    private String extractContentFromResponse(String responseBody) {
        try {
            Map<String, Object> responseMap = objectMapper.readValue(responseBody, Map.class);
            
            if (responseMap.containsKey("error")) {
                Map<String, Object> error = (Map<String, Object>) responseMap.get("error");
                throw new RuntimeException("API Error: " + error.get("message"));
            }
            
            List<Map<String, Object>> choices = (List<Map<String, Object>>) responseMap.get("choices");
            if (choices == null || choices.isEmpty()) {
                throw new RuntimeException("No choices returned from API");
            }
            
            Map<String, Object> firstChoice = choices.get(0);
            Map<String, Object> message = (Map<String, Object>) firstChoice.get("message");
            
            if (message == null) {
                throw new RuntimeException("No message in API response");
            }
            
            String content = (String) message.get("content");
            if (content == null || content.trim().isEmpty()) {
                throw new RuntimeException("Empty content returned from API");
            }
            
            return content.trim();
            
        } catch (Exception e) {
            log.error("Error parsing API response: {}", responseBody, e);
            throw new RuntimeException("Failed to parse API response: " + e.getMessage());
        }
    }
    
    /**
     * Enhance prompt based on material type
     */
    private String enhancePromptForMaterialType(String materialType, String prompt, String courseContext) {
        StringBuilder enhancedPrompt = new StringBuilder();
        
        // Add system context based on material type
        switch (materialType.toLowerCase()) {
            case "quiz":
                enhancedPrompt.append("You are an educational content creator specializing in quiz generation. ");
                enhancedPrompt.append("Create engaging, clear, and educationally sound quiz questions. ");
                break;
            case "assignment":
                enhancedPrompt.append("You are an educational content creator specializing in assignment design. ");
                enhancedPrompt.append("Create meaningful, challenging, and pedagogically effective assignments. ");
                break;
            case "lesson":
                enhancedPrompt.append("You are an educational content creator specializing in lesson planning. ");
                enhancedPrompt.append("Create structured, engaging, and comprehensive lesson content. ");
                break;
            case "worksheet":
                enhancedPrompt.append("You are an educational content creator specializing in worksheet design. ");
                enhancedPrompt.append("Create practical, interactive, and skill-building worksheet activities. ");
                break;
            case "presentation":
                enhancedPrompt.append("You are an educational content creator specializing in presentation design. ");
                enhancedPrompt.append("Create well-structured, engaging, and informative presentation content. ");
                break;
            default:
                enhancedPrompt.append("You are an educational content creator. ");
                enhancedPrompt.append("Create high-quality educational content. ");
        }
        
        // Add course context if provided
        if (courseContext != null && !courseContext.trim().isEmpty()) {
            enhancedPrompt.append("Course context: ").append(courseContext).append(" ");
        }
        
        // Add the original prompt
        enhancedPrompt.append("\n\nUser request: ").append(prompt);
        
        // Add material type specific instructions
        enhancedPrompt.append("\n\nPlease create ").append(materialType).append(" content that is:");
        enhancedPrompt.append("\n- Educationally appropriate and engaging");
        enhancedPrompt.append("\n- Clear and well-structured");
        enhancedPrompt.append("\n- Ready for classroom use");
        enhancedPrompt.append("\n- Aligned with best educational practices");
        
        return enhancedPrompt.toString();
    }
}