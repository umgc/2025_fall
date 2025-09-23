package com.careconnect.service;

import com.careconnect.dto.AIChatRequest;
import com.careconnect.dto.AIChatResponse;
import com.careconnect.dto.AIChatConversationSummary;
import com.careconnect.dto.AIChatMessageSummary;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Mock AI Chat Service for development mode when external AI services are disabled.
 * Provides fake responses to allow development and testing without real AI API calls.
 */
@Service
@Slf4j
@ConditionalOnProperty(name = "careconnect.openai.enabled", havingValue = "false")
public class MockAIChatService implements AIChatService {

    @Override
    public AIChatResponse processChat(AIChatRequest request) {
        log.info("Mock AI Chat Service: Processing chat request for user {}, patient {}",
                request.getUserId(), request.getPatientId());

        // Create a mock response
        AIChatResponse response = new AIChatResponse();
        response.setConversationId(request.getConversationId() != null ?
            request.getConversationId() : UUID.randomUUID().toString());
        response.setMessage(request.getMessage());
        response.setAiResponse("This is a mock AI response for development. " +
            "Your message was: '" + request.getMessage() + "'. " +
            "In development mode, AI services are disabled for faster testing. " +
            "Enable production mode to use real AI capabilities.");
        response.setMessageId(System.currentTimeMillis()); // Use timestamp as mock ID
        response.setAiProvider("MOCK");
        response.setModelUsed("mock-dev-model");
        response.setTokensUsed(50); // Mock token count
        response.setProcessingTimeMs(100L); // Mock processing time
        response.setTemperatureUsed(0.7);
        response.setContextIncluded(List.of("mock_context"));
        response.setIsNewConversation(request.getConversationId() == null);
        response.setTimestamp(LocalDateTime.now());
        response.setConversationTitle("Mock Conversation - " +
            (request.getMessage().length() > 30 ?
                request.getMessage().substring(0, 30) + "..." :
                request.getMessage()));
        response.setTotalMessagesInConversation(1);
        response.setTotalTokensUsedInConversation(50);
        response.setApproachingTokenLimit(false);
        response.setSuccess(true);

        return response;
    }

    @Override
    public List<AIChatConversationSummary> getPatientConversations(Long patientId) {
        log.info("Mock AI Chat Service: Getting conversations for patient {}", patientId);
        return List.of(); // Return empty list in dev mode
    }

    @Override
    public List<AIChatMessageSummary> getConversationMessages(String conversationId) {
        log.info("Mock AI Chat Service: Getting messages for conversation {}", conversationId);
        return List.of(); // Return empty list in dev mode
    }

    @Override
    public void deactivateConversation(String conversationId) {
        log.info("Mock AI Chat Service: Deactivating conversation {}", conversationId);
        // No-op in dev mode
    }
}