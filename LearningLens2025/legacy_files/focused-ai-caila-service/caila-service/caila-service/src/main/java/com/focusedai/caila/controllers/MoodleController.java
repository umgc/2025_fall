package com.focusedai.caila.controllers;

import com.focusedai.caila.services.MoodleService;
import com.focusedai.caila.utils.JwtUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor;
import java.util.Map;

@RestController
@RequestMapping("/moodle")
@RequiredArgsConstructor
public class MoodleController {
    private final MoodleService moodleService;
    private final JwtUtil jwtUtil;
    
    @PostMapping("/export")
    public ResponseEntity<Map<String, Object>> exportMaterial(@RequestBody Map<String, Object> exportData,
                                                             @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt) || !jwtUtil.isMoodleUser(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        Map<String, Object> result = moodleService.exportMaterial(jwt, exportData);
        return ResponseEntity.ok(result);
    }
    
    @GetMapping("/notes/{courseId}")
    public ResponseEntity<Map<String, Object>> getCourseNotes(@PathVariable String courseId,
                                                             @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt) || !jwtUtil.isMoodleUser(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        Map<String, Object> notes = moodleService.getCourseNotes(jwt, courseId);
        return ResponseEntity.ok(notes);
    }
    
    @GetMapping("/chat-logs/{courseId}")
    public ResponseEntity<Map<String, Object>> getChatLogs(@PathVariable String courseId,
                                                          @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt) || !jwtUtil.isMoodleUser(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        Map<String, Object> logs = moodleService.getChatLogs(jwt, courseId);
        return ResponseEntity.ok(logs);
    }
    
    private String extractJwtFromHeader(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        throw new RuntimeException("Invalid authorization header");
    }
}