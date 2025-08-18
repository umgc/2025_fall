package com.focusedai.caila.services;

import com.focusedai.caila.apis.CailaApi;
import com.focusedai.caila.models.CailaRequest;
import com.focusedai.caila.models.CailaResponse;
import com.focusedai.caila.models.MaterialRequest;
import com.focusedai.caila.models.domain.GeneratedMaterial;
import com.focusedai.caila.models.domain.ChatLog;
import com.focusedai.caila.utils.JwtUtil;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class CailaService {
    private final CailaApi cailaApi;
    private final GoogleClassroomService googleClassroomService;
    private final MoodleService moodleService;
    private final JwtUtil jwtUtil;
    
    // In-memory storage (from ChatLogService and MaterialService)
    private final Map<String, List<ChatLog>> chatLogs = new ConcurrentHashMap<>();
    private final Map<String, GeneratedMaterial> materials = new ConcurrentHashMap<>();
    private final Map<String, List<String>> teacherMaterials = new ConcurrentHashMap<>();
    
    // Original CailaService methods
    public CailaResponse processChat(CailaRequest request, String jwt) {
        try {
            String response = cailaApi.generateContent(request.getPrompt());
            
            // Store chat log
            String userId = jwtUtil.extractUserId(jwt);
            storeChatLog(userId, request.getCourseId(), request.getPrompt(), response, jwt);
            
            // Store chat log based on platform
            if (jwtUtil.isGoogleUser(jwt)) {
                googleClassroomService.storeChatLog(jwt, request, response);
            } else if (jwtUtil.isMoodleUser(jwt)) {
                moodleService.storeChatLog(jwt, request, response);
            }
            
            return CailaResponse.builder()
                    .response(response)
                    .timestamp(LocalDateTime.now())
                    .success(true)
                    .build();
        } catch (Exception e) {
            return CailaResponse.builder()
                    .error("Failed to process chat: " + e.getMessage())
                    .success(false)
                    .build();
        }
    }
    
    public CailaResponse generateMaterial(Map<String, Object> request, String jwt) {
        try {
            String prompt = (String) request.get("prompt");
            String materialType = (String) request.get("materialType");
            String courseId = (String) request.get("courseId");
            
            String content = cailaApi.generateContent(prompt);
            
            // Create material record
            GeneratedMaterial material = createMaterial(
                jwtUtil.extractUserId(jwt),
                courseId,
                (String) request.get("title"),
                materialType,
                content,
                prompt,
                jwt
            );
            
            return CailaResponse.builder()
                    .response(content)
                    .materialId(material.getId())
                    .timestamp(LocalDateTime.now())
                    .success(true)
                    .build();
        } catch (Exception e) {
            return CailaResponse.builder()
                    .error("Failed to generate material: " + e.getMessage())
                    .success(false)
                    .build();
        }
    }
    
    public Map<String, Object> getChatHistory(String jwt) {
        try {
            String userId = jwtUtil.extractUserId(jwt);
            
            if (jwtUtil.isGoogleUser(jwt)) {
                return googleClassroomService.getChatHistory(jwt, userId);
            } else if (jwtUtil.isMoodleUser(jwt)) {
                return moodleService.getChatHistory(jwt, userId);
            }
            
            return Map.of("success", false, "error", "Unsupported platform");
        } catch (Exception e) {
            return Map.of("success", false, "error", e.getMessage());
        }
    }
    
    // ChatLogService methods merged in
    public void storeChatLog(String userId, String courseId, String prompt, String response, String jwt) {
        ChatLog chatLog = ChatLog.builder()
                .id(UUID.randomUUID().toString())
                .userId(userId)
                .courseId(courseId)
                .prompt(prompt)
                .response(response)
                .platform(jwtUtil.isGoogleUser(jwt) ? "google" : "moodle")
                .timestamp(LocalDateTime.now())
                .build();
        
        String key = userId + "_" + courseId;
        chatLogs.computeIfAbsent(key, k -> new ArrayList<>()).add(chatLog);
    }
    
    public List<ChatLog> getChatLogs(String userId, String courseId) {
        String key = userId + "_" + courseId;
        return chatLogs.getOrDefault(key, new ArrayList<>());
    }
    
    // MaterialService methods merged in
    public GeneratedMaterial generateMaterial(MaterialRequest request, String jwt) {
        String teacherId = jwtUtil.extractUserId(jwt);
        return createMaterial(teacherId, request.getCourseId(), request.getTitle(), 
                request.getMaterialType(), request.getContent(), request.getPrompt(), jwt);
    }
    
    public GeneratedMaterial createMaterial(String teacherId, String courseId, String title, 
                                          String materialType, String content, String prompt, String jwt) {
        GeneratedMaterial material = GeneratedMaterial.builder()
                .id(UUID.randomUUID().toString())
                .teacherId(teacherId)
                .courseId(courseId)
                .title(title)
                .type(materialType)
                .content(content)
                .prompt(prompt)
                .platform(jwtUtil.isGoogleUser(jwt) ? "google" : "moodle")
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .version(1)
                .build();
        
        materials.put(material.getId(), material);
        teacherMaterials.computeIfAbsent(teacherId, k -> new ArrayList<>()).add(material.getId());
        
        return material;
    }
    
    public List<GeneratedMaterial> getTeacherMaterials(String teacherId, String jwt) {
        List<String> materialIds = teacherMaterials.getOrDefault(teacherId, new ArrayList<>());
        return materialIds.stream()
                .map(materials::get)
                .filter(Objects::nonNull)
                .sorted(Comparator.comparing(GeneratedMaterial::getUpdatedAt).reversed())
                .toList();
    }
    
    public GeneratedMaterial getMaterial(String materialId, String jwt) {
        GeneratedMaterial material = materials.get(materialId);
        if (material == null) {
            throw new RuntimeException("Material not found");
        }
        return material;
    }
}