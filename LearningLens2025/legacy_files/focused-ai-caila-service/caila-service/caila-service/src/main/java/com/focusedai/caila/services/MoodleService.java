package com.focusedai.caila.services;

import com.focusedai.caila.apis.moodle.MoodleApi;
import com.focusedai.caila.models.CailaRequest;
import com.focusedai.caila.utils.JwtUtil;
import com.focusedai.caila.utils.ContentFormatter;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import java.util.*;

@Service
@RequiredArgsConstructor
public class MoodleService {
    private final MoodleApi moodleApi;
    private final JwtUtil jwtUtil;
    private final ContentFormatter contentFormatter;
    
    public Map<String, Object> exportMaterial(String jwt, Map<String, Object> exportData) {
        try {
            String moodleUrl = jwtUtil.extractMoodleDomain(jwt);
            String webServiceToken = jwtUtil.extractwebServiceToken(jwt);
            String userId = jwtUtil.extractUserId(jwt);
            String courseId = (String) exportData.get("courseId");
            String content = (String) exportData.get("content");
            
            String formattedContent = contentFormatter.formatForMoodle(content, 
                    (String) exportData.get("materialType"));
            
            Map<String, Object> result = moodleApi.createNote(moodleUrl, webServiceToken, 
                    userId, courseId, formattedContent);
            
            return Map.of("success", true, "noteId", result.get("id"));
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    public void storeChatLog(String jwt, CailaRequest request, String response) {
        try {
            String moodleUrl = jwtUtil.extractMoodleDomain(jwt);
            String webServiceToken = jwtUtil.extractwebServiceToken(jwt);
            String userId = jwtUtil.extractUserId(jwt);
            
            String content = contentFormatter.formatChatLog(request, response);
            
            moodleApi.createNote(moodleUrl, webServiceToken, userId, 
                    request.getCourseId(), content);
        } catch (Exception e) {
            // Log error but don't fail the chat
            System.err.println("Failed to store chat log: " + e.getMessage());
        }
    }
    
    public Map<String, Object> getCourseNotes(String jwt, String courseId) {
        try {
            String moodleUrl = jwtUtil.extractMoodleDomain(jwt);
            String webServiceToken = jwtUtil.extractwebServiceToken(jwt);
            String userId = jwtUtil.extractUserId(jwt);
            
            List<Map<String, Object>> notes = moodleApi.getCourseNotes(moodleUrl, 
                    webServiceToken, courseId, userId);
            
            return Map.of("success", true, "notes", notes);
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    public Map<String, Object> getChatLogs(String jwt, String courseId) {
        try {
            String moodleUrl = jwtUtil.extractMoodleDomain(jwt);
            String webServiceToken = jwtUtil.extractwebServiceToken(jwt);
            String userId = jwtUtil.extractUserId(jwt);
            
            List<Map<String, Object>> notes = moodleApi.getCourseNotes(moodleUrl, 
                    webServiceToken, courseId, userId);
            
            // Filter for chat logs
            List<Map<String, Object>> chatLogs = notes.stream()
                    .filter(note -> note.get("content").toString().contains("CAILA Chat"))
                    .toList();
            
            return Map.of("success", true, "logs", chatLogs);
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    public Map<String, Object> getChatHistory(String jwt, String userId) {
        try {
            // Implementation would retrieve chat history from Moodle notes
            return Map.of("success", true, "history", new ArrayList<>());
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
}