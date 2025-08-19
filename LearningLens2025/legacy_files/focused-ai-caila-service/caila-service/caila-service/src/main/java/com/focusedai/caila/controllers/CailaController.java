package com.focusedai.caila.controllers;

import com.focusedai.caila.services.CailaService;
import com.focusedai.caila.models.CailaRequest;
import com.focusedai.caila.models.CailaResponse;
import com.focusedai.caila.models.MaterialRequest;
import com.focusedai.caila.models.domain.GeneratedMaterial;
import com.focusedai.caila.utils.JwtUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/caila")
@RequiredArgsConstructor
public class CailaController {
    private final CailaService cailaService;
    private final JwtUtil jwtUtil;
    
    // Original CailaController methods
    @PostMapping("/chat")
    public ResponseEntity<CailaResponse> chat(@RequestBody CailaRequest request,
                                             @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        CailaResponse response = cailaService.processChat(request, jwt);
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/generate")
    public ResponseEntity<CailaResponse> generateMaterial(@RequestBody Map<String, Object> request,
                                                         @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        CailaResponse response = cailaService.generateMaterial(request, jwt);
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/history")
    public ResponseEntity<Map<String, Object>> getChatHistory(@RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        Map<String, Object> history = cailaService.getChatHistory(jwt);
        return ResponseEntity.ok(history);
    }
    
    // MaterialController methods merged in
    @PostMapping("/materials/generate")
    public ResponseEntity<GeneratedMaterial> generateMaterialFromRequest(@RequestBody MaterialRequest request,
                                                             @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        GeneratedMaterial material = cailaService.generateMaterial(request, jwt);
        return ResponseEntity.ok(material);
    }
    
    @GetMapping("/materials/teacher/{teacherId}")
    public ResponseEntity<List<GeneratedMaterial>> getTeacherMaterials(@PathVariable String teacherId,
                                                                      @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        List<GeneratedMaterial> materials = cailaService.getTeacherMaterials(teacherId, jwt);
        return ResponseEntity.ok(materials);
    }
    
    @GetMapping("/materials/{materialId}")
    public ResponseEntity<GeneratedMaterial> getMaterial(@PathVariable String materialId,
                                                        @RequestHeader("Authorization") String authHeader) {
        String jwt = extractJwtFromHeader(authHeader);
        
        if (!jwtUtil.validateToken(jwt)) {
            return ResponseEntity.status(401).build();
        }
        
        GeneratedMaterial material = cailaService.getMaterial(materialId, jwt);
        return ResponseEntity.ok(material);
    }
    
    private String extractJwtFromHeader(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        throw new RuntimeException("Invalid authorization header");
    }
}