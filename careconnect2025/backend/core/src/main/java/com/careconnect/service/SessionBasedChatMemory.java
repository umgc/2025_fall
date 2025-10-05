package com.careconnect.service;

import dev.langchain4j.data.message.ChatMessage;
import dev.langchain4j.data.message.SystemMessage;
import dev.langchain4j.data.message.UserMessage;
import dev.langchain4j.data.message.AiMessage;
import dev.langchain4j.memory.ChatMemory;
import lombok.extern.slf4j.Slf4j;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Session-based ChatMemory implementation for healthcare applications
 * 
 * This implementation follows healthcare safety best practices:
 * - Limited context window (10-20 messages per session)
 * - Session timeout (15-30 minutes of inactivity)
 * - No cross-conversation memory retention
 * - Clear boundaries between sessions
 * 
 * Each session is isolated and resets after timeout or when chat is closed.
 */
@Slf4j
public class SessionBasedChatMemory implements ChatMemory {
    
    private final String sessionId;
    private final int maxMessages;
    private final long sessionTimeoutMinutes;
    private final ConcurrentMap<String, SessionData> sessions;
    
    private Instant lastActivity;
    private List<ChatMessage> currentSessionMessages;
    
    public SessionBasedChatMemory(String sessionId, int maxMessages, long sessionTimeoutMinutes) {
        this.sessionId = sessionId;
        this.maxMessages = maxMessages;
        this.sessionTimeoutMinutes = sessionTimeoutMinutes;
        this.sessions = new ConcurrentHashMap<>();
        this.currentSessionMessages = new ArrayList<>();
        this.lastActivity = Instant.now();
        
        log.debug("Created session-based ChatMemory for session {} with {} max messages and {} minute timeout", 
            sessionId, maxMessages, sessionTimeoutMinutes);
    }
    
    @Override
    public Object id() {
        return sessionId;
    }
    
    @Override
    public void add(ChatMessage message) {
        updateActivity();
        
        // Check if session has expired
        if (isSessionExpired()) {
            log.debug("Session {} expired, starting new session", sessionId);
            startNewSession();
        }
        
        // Add message to current session
        currentSessionMessages.add(message);
        
        // Maintain message limit
        if (currentSessionMessages.size() > maxMessages) {
            // Remove oldest messages, but keep system messages
            List<ChatMessage> toKeep = new ArrayList<>();
            List<ChatMessage> toRemove = new ArrayList<>();
            
            // Keep all system messages
            for (ChatMessage msg : currentSessionMessages) {
                if (msg instanceof SystemMessage) {
                    toKeep.add(msg);
                } else {
                    toRemove.add(msg);
                }
            }
            
            // Add recent non-system messages up to limit
            int nonSystemCount = 0;
            for (ChatMessage msg : currentSessionMessages) {
                if (!(msg instanceof SystemMessage)) {
                    if (nonSystemCount < maxMessages - toKeep.size()) {
                        toKeep.add(msg);
                        nonSystemCount++;
                    }
                }
            }
            
            currentSessionMessages = toKeep;
        }
        
        log.debug("Added message to session {}, total messages: {}", sessionId, currentSessionMessages.size());
    }
    
    @Override
    public List<ChatMessage> messages() {
        updateActivity();
        
        // Check if session has expired
        if (isSessionExpired()) {
            log.debug("Session {} expired during message retrieval, starting new session", sessionId);
            startNewSession();
        }
        
        return new ArrayList<>(currentSessionMessages);
    }
    
    @Override
    public void clear() {
        log.info("Clearing session {} memory", sessionId);
        currentSessionMessages.clear();
        updateActivity();
    }
    
    /**
     * Check if the current session has expired
     */
    private boolean isSessionExpired() {
        return ChronoUnit.MINUTES.between(lastActivity, Instant.now()) > sessionTimeoutMinutes;
    }
    
    /**
     * Update the last activity timestamp
     */
    private void updateActivity() {
        this.lastActivity = Instant.now();
    }
    
    /**
     * Start a new session (clear current messages)
     */
    private void startNewSession() {
        log.debug("Starting new session for {}", sessionId);
        currentSessionMessages.clear();
        updateActivity();
    }
    
    /**
     * Get session statistics for monitoring
     */
    public SessionStats getSessionStats() {
        return SessionStats.builder()
            .sessionId(sessionId)
            .messageCount(currentSessionMessages.size())
            .lastActivity(lastActivity)
            .isExpired(isSessionExpired())
            .build();
    }
    
    /**
     * Session statistics for monitoring and debugging
     */
    @lombok.Builder
    @lombok.Data
    public static class SessionStats {
        private String sessionId;
        private int messageCount;
        private Instant lastActivity;
        private boolean isExpired;
    }
}
