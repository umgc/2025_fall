package com.example.demo.controller;

import com.example.demo.dto.*;
import com.example.demo.service.AltumViewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@RestController
@RequestMapping("/api/skeleton")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // Configure properly for production
public class SkeletonController {
    
    private final AltumViewService altumViewService;
    
    @GetMapping("/cameras")
    public ResponseEntity<List<Camera>> getCameras() {
        return ResponseEntity.ok(altumViewService.getCameras());
    }
    
    @GetMapping("/stream-config/{cameraId}")
    public ResponseEntity<SkeletonStreamConfig> getStreamConfig(@PathVariable Long cameraId) {
        return ResponseEntity.ok(altumViewService.getSkeletonStreamConfig(cameraId));
    }
    
    @GetMapping("/alerts")
    public ResponseEntity<List<Alert>> getAlerts(@RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(altumViewService.getAlerts(limit));
    }
    
    @GetMapping("/alerts/{alertId}")
    public ResponseEntity<Alert> getAlert(@PathVariable String alertId) {
        return ResponseEntity.ok(altumViewService.getAlertById(alertId));
    }
    
    /**
     * Get fresh background image URL for an alert
     * This returns a new pre-signed S3 URL that won't be expired
     */
    @GetMapping("/alerts/{alertId}/background-url")
    public ResponseEntity<Map<String, String>> getAlertBackgroundUrl(@PathVariable String alertId) {
        try {
            String backgroundUrl = altumViewService.getAlertBackgroundUrl(alertId);
            return ResponseEntity.ok(Map.of("background_url", backgroundUrl));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    /**
     * Proxy endpoint to fetch background image and serve it
     * This avoids CORS issues with S3 signed URLs
     */
    @GetMapping("/alerts/{alertId}/background-image")
    public ResponseEntity<byte[]> getAlertBackgroundImage(@PathVariable String alertId) {
        try {
            byte[] imageBytes = altumViewService.getAlertBackground(alertId);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.IMAGE_JPEG);
            headers.setCacheControl("no-cache");
            
            return new ResponseEntity<>(imageBytes, headers, HttpStatus.OK);
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new byte[0]);
        }
    }
    
    /**
     * Get video clip URL for an alert
     */
    @GetMapping("/alerts/{alertId}/video-url")
    public ResponseEntity<Map<String, String>> getAlertVideoUrl(@PathVariable String alertId) {
        try {
            String videoUrl = altumViewService.getAlertVideoUrl(alertId);
            return ResponseEntity.ok(Map.of("video_url", videoUrl));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/alerts/{alertId}/skeleton")
    public ResponseEntity<Map<String, Object>> getAlertSkeletonFile(@PathVariable String alertId) {
        try {
            Alert alert = altumViewService.getAlertById(alertId);
            
            Map<String, Object> response = new java.util.HashMap<>();
            response.put("alert_id", alert.getId());
            response.put("has_skeleton_file", alert.getSkeletonFile() != null && !alert.getSkeletonFile().isEmpty());
            
            if (alert.getSkeletonFile() != null && !alert.getSkeletonFile().isEmpty()) {
                response.put("skeleton_file_length", alert.getSkeletonFile().length());
                response.put("skeleton_file_preview", alert.getSkeletonFile().substring(0, Math.min(100, alert.getSkeletonFile().length())));
                
                // Try to decode and validate
                try {
                    byte[] decoded = java.util.Base64.getDecoder().decode(alert.getSkeletonFile());
                    response.put("decoded_bytes_length", decoded.length);
                    
                    // Try to parse as UTF-8 string
                    String decodedString = new String(decoded, java.nio.charset.StandardCharsets.UTF_8);
                    response.put("decoded_string_length", decodedString.length());
                    response.put("decoded_string_preview", decodedString.substring(0, Math.min(200, decodedString.length())));
                    
                    response.put("decode_success", true);
                } catch (Exception e) {
                    response.put("decode_success", false);
                    response.put("decode_error", e.getMessage());
                }
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/alerts/{alertId}/skeleton-decoded")
    public ResponseEntity<Map<String, Object>> getAlertSkeletonDecoded(@PathVariable String alertId) {
        try {
            Alert alert = altumViewService.getAlertById(alertId);
            
            if (alert.getSkeletonFile() == null || alert.getSkeletonFile().isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "No skeleton data available for this alert"));
            }
            
            // Decode using the Recording format (not MQTT stream format!)
            // Alerts use the Skeleton Recordings Binary Format from /recordings API
            Map<String, Object> skeletonData = com.example.demo.util.SkeletonRecordingDecoder.decode(alert.getSkeletonFile());
            
            return ResponseEntity.ok(skeletonData);
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to decode skeleton data: " + e.getMessage()));
        }
    }
    
    @GetMapping("/cameras/{cameraId}/view")
    public ResponseEntity<byte[]> getCameraView(@PathVariable Long cameraId) {
        try {
            byte[] imageBytes = altumViewService.getCameraView(cameraId);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.IMAGE_JPEG);
            headers.setContentLength(imageBytes.length);
            
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(imageBytes);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }
    
    @GetMapping("/cameras/{cameraId}/background")
    public ResponseEntity<byte[]> getCameraBackground(@PathVariable Long cameraId) {
        try {
            // Proxy the image through our backend to avoid CORS issues
            byte[] imageBytes = altumViewService.getCameraBackground(cameraId);
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.IMAGE_JPEG);
            headers.setContentLength(imageBytes.length);
            
            return ResponseEntity.ok()
                    .headers(headers)
                    .body(imageBytes);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(null);
        }
    }
}