package com.careconnect.service;

import dev.langchain4j.memory.ChatMemory;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import com.careconnect.model.ChatConversation;
import com.careconnect.model.UserAIConfig;
import com.careconnect.repository.ChatMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * Factory for creating ChatMemory instances with different strategies
 * 
 * Provides both in-memory and database-persistent chat memory options
 * based on configuration and requirements.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ChatMemoryFactory {
    
    private final ChatMessageRepository chatMessageRepository;
    
    /**
     * Create a ChatMemory instance for the given conversation and configuration
     * 
     * @param conversation The chat conversation
     * @param aiConfig User AI configuration (for memory limits)
     * @param useDatabase Whether to use database persistence (true) or in-memory (false)
     * @return ChatMemory instance
     */
    public ChatMemory createChatMemory(ChatConversation conversation, 
                                     UserAIConfig aiConfig, 
                                     boolean useDatabase) {
        
        int maxMessages = getMaxMessages(aiConfig);
        
        if (useDatabase) {
            log.debug("Creating database-persistent ChatMemory for conversation {} with {} max messages", 
                conversation.getConversationId(), maxMessages);
            return new DatabaseChatMemory(chatMessageRepository, conversation, maxMessages);
        } else {
            log.debug("Creating in-memory ChatMemory for conversation {} with {} max messages", 
                conversation.getConversationId(), maxMessages);
            return MessageWindowChatMemory.withMaxMessages(maxMessages);
        }
    }
    
    /**
     * Create a database-persistent ChatMemory (recommended for production)
     */
    public ChatMemory createDatabaseChatMemory(ChatConversation conversation, UserAIConfig aiConfig) {
        return createChatMemory(conversation, aiConfig, true);
    }
    
    /**
     * Create an in-memory ChatMemory (useful for testing or temporary conversations)
     */
    public ChatMemory createInMemoryChatMemory(ChatConversation conversation, UserAIConfig aiConfig) {
        return createChatMemory(conversation, aiConfig, false);
    }
    
    /**
     * Get the maximum number of messages from AI config or use default
     */
    private int getMaxMessages(UserAIConfig aiConfig) {
        if (aiConfig != null && aiConfig.getConversationHistoryLimit() != null) {
            return aiConfig.getConversationHistoryLimit();
        }
        return 20; // Default limit
    }
}
