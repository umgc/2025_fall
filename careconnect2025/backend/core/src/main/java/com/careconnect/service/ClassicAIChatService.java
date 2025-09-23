package com.careconnect.service;

import java.util.List;

import com.careconnect.dto.AIChatConversationSummary;
import com.careconnect.dto.AIChatMessageSummary;
import com.careconnect.dto.AIChatRequest;
import com.careconnect.dto.AIChatResponse;
// import reactor.core.publisher.Mono; // Removed Mono import

public class ClassicAIChatService implements AIChatService {
    @Override
    public List<AIChatConversationSummary> getPatientConversations(Long patientId) {
        throw new UnsupportedOperationException("Not implemented in ClassicAIChatService");
    }

    @Override
    public List<AIChatMessageSummary> getConversationMessages(String conversationId) {
        throw new UnsupportedOperationException("Not implemented in ClassicAIChatService");
    }

    @Override
    public void deactivateConversation(String conversationId) {
        throw new UnsupportedOperationException("Not implemented in ClassicAIChatService");
    }
    @Override
    public AIChatResponse processChat(AIChatRequest request) {
        return AIChatResponse.builder()
                .success(true)
                .aiResponse("Classic AI response")
                .build();
    }
    // ...other methods as needed
}
