package com.careconnect.service;

import java.util.List;

import com.careconnect.dto.AIChatConversationSummary;
import com.careconnect.dto.AIChatMessageSummary;
import com.careconnect.dto.AIChatRequest;
import com.careconnect.dto.AIChatResponse;

public interface AIChatService {
    AIChatResponse processChat(AIChatRequest request);

    // Conversation management
    List<AIChatConversationSummary> getPatientConversations(Long patientId);
    List<AIChatMessageSummary> getConversationMessages(String conversationId);
    void deactivateConversation(String conversationId);
}
