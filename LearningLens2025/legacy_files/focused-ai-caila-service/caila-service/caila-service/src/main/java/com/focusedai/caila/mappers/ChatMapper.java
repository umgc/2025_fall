// File: src/main/java/com/focusedai/caila/mappers/ChatMapper.java
package com.focusedai.caila.mappers;

import com.focusedai.caila.models.domain.ChatLog;
import com.focusedai.caila.models.CailaRequest;
import com.focusedai.caila.models.CailaResponse;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.*;

@Component
public class ChatMapper {
    
    /**
     * Create ChatLog from request and response
     */
    public ChatLog createChatLog(String userId, String courseId, String prompt, 
                                String response, String platform, String sessionId) {
        return ChatLog.builder()
                .id(UUID.randomUUID().toString())
                .userId(userId)
                .courseId(courseId)
                .prompt(prompt)
                .response(response)
                .platform(platform)
                .sessionId(sessionId)
                .timestamp(LocalDateTime.now())
                .build();
    }
    
    /**
     * Create ChatLog from CailaRequest and response
     */
    public ChatLog fromCailaRequest(CailaRequest request, String response, String platform) {
        return ChatLog.builder()
                .id(UUID.randomUUID().toString())
                .userId(extractUserIdFromRequest(request))
                .courseId(request.getCourseId())
                .prompt(request.getPrompt())
                .response(response)
                .platform(platform)
                .sessionId(request.getSessionId())
                .timestamp(LocalDateTime.now())
                .build();
    }
    
    /**
     * Convert ChatLog to CailaResponse format
     */
    public CailaResponse toCailaResponse(ChatLog chatLog) {
        return CailaResponse.builder()
                .response(chatLog.getResponse())
                .sessionId(chatLog.getSessionId())
                .timestamp(chatLog.getTimestamp())
                .success(true)
                .build();
    }
    
    /**
     * Map ChatLog to API response format
     */
    public Map<String, Object> toApiResponse(ChatLog chatLog) {
        Map<String, Object> response = new HashMap<>();
        response.put("id", chatLog.getId());
        response.put("userId", chatLog.getUserId());
        response.put("courseId", chatLog.getCourseId());
        response.put("prompt", chatLog.getPrompt());
        response.put("response", chatLog.getResponse());
        response.put("platform", chatLog.getPlatform());
        response.put("sessionId", chatLog.getSessionId());
        response.put("timestamp", chatLog.getTimestamp().toString());
        return response;
    }
    
    /**
     * Map list of ChatLogs to API response format
     */
    public List<Map<String, Object>> toApiResponseList(List<ChatLog> chatLogs) {
        List<Map<String, Object>> responseList = new ArrayList<>();
        for (ChatLog chatLog : chatLogs) {
            responseList.add(toApiResponse(chatLog));
        }
        return responseList;
    }
    
    /**
     * Create teacher chat session summary
     */
    public Map<String, Object> createTeacherChatSummary(List<ChatLog> chatLogs, String teacherId, String materialType) {
        Map<String, Object> summary = new HashMap<>();
        
        if (chatLogs.isEmpty()) {
            summary.put("teacherId", teacherId);
            summary.put("materialType", materialType);
            summary.put("messageCount", 0);
            summary.put("sessions", new ArrayList<>());
            summary.put("totalSessions", 0);
            return summary;
        }
        
        // Group by session
        Map<String, List<ChatLog>> sessionGroups = new HashMap<>();
        for (ChatLog chatLog : chatLogs) {
            String sessionId = chatLog.getSessionId();
            sessionGroups.computeIfAbsent(sessionId, k -> new ArrayList<>()).add(chatLog);
        }
        
        // Create session summaries
        List<Map<String, Object>> sessions = new ArrayList<>();
        for (Map.Entry<String, List<ChatLog>> entry : sessionGroups.entrySet()) {
            String sessionId = entry.getKey();
            List<ChatLog> sessionLogs = entry.getValue();
            
            // Sort by timestamp
            sessionLogs.sort(Comparator.comparing(ChatLog::getTimestamp));
            
            Map<String, Object> sessionSummary = new HashMap<>();
            sessionSummary.put("sessionId", sessionId);
            sessionSummary.put("messageCount", sessionLogs.size());
            sessionSummary.put("startTime", sessionLogs.get(0).getTimestamp().toString());
            sessionSummary.put("lastActivity", sessionLogs.get(sessionLogs.size() - 1).getTimestamp().toString());
            sessionSummary.put("courseId", sessionLogs.get(0).getCourseId());
            sessionSummary.put("materialType", materialType);
            
            // Preview of first prompt
            String firstPrompt = sessionLogs.get(0).getPrompt();
            if (firstPrompt.length() > 100) {
                firstPrompt = firstPrompt.substring(0, 100) + "...";
            }
            sessionSummary.put("preview", firstPrompt);
            
            sessions.add(sessionSummary);
        }
        
        // Sort sessions by last activity (newest first)
        sessions.sort((a, b) -> {
            String timeA = (String) a.get("lastActivity");
            String timeB = (String) b.get("lastActivity");
            return timeB.compareTo(timeA);
        });
        
        summary.put("teacherId", teacherId);
        summary.put("materialType", materialType);
        summary.put("messageCount", chatLogs.size());
        summary.put("sessions", sessions);
        summary.put("totalSessions", sessions.size());
        summary.put("platform", chatLogs.get(0).getPlatform());
        
        return summary;
    }
    
    /**
     * Create student chat summary for teacher view
     */
    public Map<String, Object> createStudentChatSummary(List<ChatLog> chatLogs, String studentId, String courseId) {
        Map<String, Object> summary = new HashMap<>();
        
        if (chatLogs.isEmpty()) {
            summary.put("studentId", studentId);
            summary.put("courseId", courseId);
            summary.put("entries", new ArrayList<>());
            summary.put("totalEntries", 0);
            summary.put("lastUpdated", null);
            return summary;
        }
        
        // Sort by timestamp (newest first)
        List<ChatLog> sortedLogs = new ArrayList<>(chatLogs);
        sortedLogs.sort((a, b) -> b.getTimestamp().compareTo(a.getTimestamp()));
        
        // Convert to entries format
        List<Map<String, Object>> entries = new ArrayList<>();
        for (ChatLog chatLog : sortedLogs) {
            Map<String, Object> entry = new HashMap<>();
            entry.put("timestamp", chatLog.getTimestamp().toString());
            entry.put("student", chatLog.getPrompt());
            entry.put("caila", chatLog.getResponse());
            entry.put("sessionId", chatLog.getSessionId());
            entries.add(entry);
        }
        
        summary.put("studentId", studentId);
        summary.put("courseId", courseId);
        summary.put("entries", entries);
        summary.put("totalEntries", entries.size());
        summary.put("lastUpdated", sortedLogs.get(0).getTimestamp().toString());
        summary.put("platform", sortedLogs.get(0).getPlatform());
        summary.put("fullContent", buildFullContentString(sortedLogs));
        
        return summary;
    }
    
    /**
     * Map chat logs to conversation format
     */
    public List<Map<String, Object>> toConversationFormat(List<ChatLog> chatLogs) {
        List<Map<String, Object>> conversation = new ArrayList<>();
        
        for (ChatLog chatLog : chatLogs) {
            // Add student message
            Map<String, Object> studentMessage = new HashMap<>();
            studentMessage.put("role", "student");
            studentMessage.put("content", chatLog.getPrompt());
            studentMessage.put("timestamp", chatLog.getTimestamp().toString());
            conversation.add(studentMessage);
            
            // Add CAILA response
            Map<String, Object> cailaMessage = new HashMap<>();
            cailaMessage.put("role", "caila");
            cailaMessage.put("content", chatLog.getResponse());
            cailaMessage.put("timestamp", chatLog.getTimestamp().toString());
            conversation.add(cailaMessage);
        }
        
        return conversation;
    }
    
    /**
     * Extract conversation context from chat logs
     */
    public String buildConversationContext(List<ChatLog> recentChatLogs, int maxMessages) {
        if (recentChatLogs.isEmpty()) {
            return "";
        }
        
        StringBuilder context = new StringBuilder();
        context.append("Previous conversation:\n");
        
        // Sort by timestamp and take most recent
        List<ChatLog> sortedLogs = new ArrayList<>(recentChatLogs);
        sortedLogs.sort(Comparator.comparing(ChatLog::getTimestamp));
        
        int limit = Math.min(maxMessages, sortedLogs.size());
        List<ChatLog> limitedLogs = sortedLogs.subList(Math.max(0, sortedLogs.size() - limit), sortedLogs.size());
        
        for (ChatLog chatLog : limitedLogs) {
            context.append("Student: ").append(chatLog.getPrompt()).append("\n");
            context.append("CAILA: ").append(chatLog.getResponse()).append("\n\n");
        }
        
        return context.toString();
    }
    
    /**
     * Create chat statistics
     */
    public Map<String, Object> createChatStatistics(List<ChatLog> chatLogs) {
        Map<String, Object> stats = new HashMap<>();
        
        if (chatLogs.isEmpty()) {
            stats.put("totalMessages", 0);
            stats.put("uniqueSessions", 0);
            stats.put("uniqueUsers", 0);
            stats.put("uniqueCourses", 0);
            stats.put("averageResponseLength", 0);
            return stats;
        }
        
        Set<String> uniqueSessions = new HashSet<>();
        Set<String> uniqueUsers = new HashSet<>();
        Set<String> uniqueCourses = new HashSet<>();
        int totalResponseLength = 0;
        
        for (ChatLog chatLog : chatLogs) {
            uniqueSessions.add(chatLog.getSessionId());
            uniqueUsers.add(chatLog.getUserId());
            uniqueCourses.add(chatLog.getCourseId());
            totalResponseLength += chatLog.getResponse().length();
        }
        
        stats.put("totalMessages", chatLogs.size());
        stats.put("uniqueSessions", uniqueSessions.size());
        stats.put("uniqueUsers", uniqueUsers.size());
        stats.put("uniqueCourses", uniqueCourses.size());
        stats.put("averageResponseLength", totalResponseLength / chatLogs.size());
        stats.put("firstActivity", chatLogs.stream()
                .map(ChatLog::getTimestamp)
                .min(LocalDateTime::compareTo)
                .map(LocalDateTime::toString)
                .orElse(null));
        stats.put("lastActivity", chatLogs.stream()
                .map(ChatLog::getTimestamp)
                .max(LocalDateTime::compareTo)
                .map(LocalDateTime::toString)
                .orElse(null));
        
        return stats;
    }
    
    // Helper methods
    private String extractUserIdFromRequest(CailaRequest request) {
        // Try to extract user ID from various possible fields
        if (request.getStudentId() != null) {
            return request.getStudentId();
        }
        if (request.getTeacherEmail() != null) {
            return request.getTeacherEmail();
        }
        // Fallback to session ID or generate one
        return request.getSessionId() != null ? request.getSessionId() : "unknown_user";
    }
    
    private String buildFullContentString(List<ChatLog> chatLogs) {
        StringBuilder fullContent = new StringBuilder();
        
        fullContent.append("CAILA Chat History\n");
        fullContent.append("=".repeat(50)).append("\n\n");
        
        for (ChatLog chatLog : chatLogs) {
            fullContent.append("[").append(chatLog.getTimestamp().toString()).append("]\n");
            fullContent.append("STUDENT: ").append(chatLog.getPrompt()).append("\n\n");
            fullContent.append("CAILA: ").append(chatLog.getResponse()).append("\n\n");
            fullContent.append("-".repeat(50)).append("\n\n");
        }
        
        return fullContent.toString();
    }
}