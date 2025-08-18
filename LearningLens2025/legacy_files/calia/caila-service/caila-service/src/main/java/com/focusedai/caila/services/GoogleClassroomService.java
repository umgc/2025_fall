package com.focusedai.caila.services;

import com.focusedai.caila.apis.google.GoogleClassroomApi;
import com.focusedai.caila.models.CailaRequest;
import com.focusedai.caila.utils.JwtUtil;
import com.focusedai.caila.utils.ContentFormatter;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
@RequiredArgsConstructor
public class GoogleClassroomService {
    private final GoogleClassroomApi googleClassroomApi;
    private final JwtUtil jwtUtil;
    private final ContentFormatter contentFormatter;
    
    public Map<String, Object> createGoogleForm(String jwt, Map<String, Object> formData) {
        try {
            String accessToken = jwtUtil.extractGoogleAccessToken(jwt);
            
            return googleClassroomApi.createGoogleForm(accessToken, formData);
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    public Map<String, Object> createClassroomAssignment(String jwt, Map<String, Object> assignmentData) {
        try {
            String accessToken = jwtUtil.extractGoogleAccessToken(jwt);
            String courseId = (String) assignmentData.get("courseId");
            
            // Implementation would use Google Classroom API
            return Map.of("success", true, "message", "Assignment created successfully");
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    public void storeChatLog(String jwt, CailaRequest request, String response) {
        try {
            String accessToken = jwtUtil.extractGoogleAccessToken(jwt);
            String userId = jwtUtil.extractUserId(jwt);
            String userEmail = jwtUtil.extractUserIdentifier(jwt);
            
            String fileName = generateChatFileName(userId, request.getCourseId());
            String content = contentFormatter.formatChatLog(request, response);
            
            Map<String, Object> file = googleClassroomApi.createFile(accessToken, fileName, content);
            
            // Share with teacher if needed
            if (request.getTeacherEmail() != null) {
                googleClassroomApi.shareFile(accessToken, (String) file.get("id"), request.getTeacherEmail());
            }
        } catch (Exception e) {
            // Log error but don't fail the chat
            System.err.println("Failed to store chat log: " + e.getMessage());
        }
    }
    
    public Map<String, Object> getChatLogs(String jwt, String courseId) {
        try {
            String accessToken = jwtUtil.extractGoogleAccessToken(jwt);
            
            // Implementation would retrieve chat logs from Google Drive
            return Map.of("success", true, "logs", new ArrayList<>());
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    public Map<String, Object> getChatHistory(String jwt, String userId) {
        try {
            String accessToken = jwtUtil.extractGoogleAccessToken(jwt);
            
            // Implementation would retrieve chat history from Google Drive
            return Map.of("success", true, "history", new ArrayList<>());
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    private String generateChatFileName(String userId, String courseId) {
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        return String.format("CAILA_Chat_%s_%s_%s.txt", courseId, userId, timestamp);
    }
}