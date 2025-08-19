package com.focusedai.caila.controllers;

import com.focusedai.caila.services.GoogleClassroomService;
import com.focusedai.caila.utils.JwtUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor;
import java.util.Map;

@RestController
@RequestMapping("/google")
@RequiredArgsConstructor
public class GoogleController {
    private final GoogleClassroomService googleClassroomService;
    private final JwtUtil jwtUtil;
    
    @PostMapping("/forms/create")
    public ResponseEntity<Map<String, Object>> createForm(@RequestBody Map<String, Object> formData,
                                                         @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt) || !jwtUtil.isGoogleUser(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        Map<String, Object> result = googleClassroomService.createGoogleForm(jwt, formData);
        return ResponseEntity.ok(result);
    }
    
    @PostMapping("/classroom/assignment")
    public ResponseEntity<Map<String, Object>> createClassroomAssignment(
            @RequestBody Map<String, Object> assignmentData,
            @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt) || !jwtUtil.isGoogleUser(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        Map<String, Object> result = googleClassroomService.createClassroomAssignment(jwt, assignmentData);
        return ResponseEntity.ok(result);
    }
    
    @GetMapping("/drive/chat-logs/{courseId}")
    public ResponseEntity<Map<String, Object>> getChatLogs(@PathVariable String courseId,
                                                          @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt) || !jwtUtil.isGoogleUser(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        Map<String, Object> logs = googleClassroomService.getChatLogs(jwt, courseId);
        return ResponseEntity.ok(logs);
    }
    
    private String extractJwtFromHeader(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        throw new RuntimeException("Invalid authorization header");
    }
}