package com.focusedai.caila.apis.google;

import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import lombok.RequiredArgsConstructor;
import java.util.*;

@Service
@RequiredArgsConstructor
public class GoogleClassroomApi {
    private final RestTemplate restTemplate;
    private final String DRIVE_API_BASE = "https://www.googleapis.com/drive/v3";
    private final String FORMS_API_BASE = "https://forms.googleapis.com/v1";
    
    public Map<String, Object> createFile(String accessToken, String fileName, String content) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.MULTIPART_RELATED);
            
            String boundary = "caila_boundary_" + System.currentTimeMillis();
            headers.set("Content-Type", "multipart/related; boundary=" + boundary);
            
            StringBuilder multipartBody = new StringBuilder();
            multipartBody.append("--").append(boundary).append("\r\n");
            multipartBody.append("Content-Type: application/json; charset=UTF-8\r\n\r\n");
            multipartBody.append("{\r\n");
            multipartBody.append("  \"name\": \"").append(fileName).append("\",\r\n");
            multipartBody.append("  \"mimeType\": \"text/plain\"\r\n");
            multipartBody.append("}\r\n");
            multipartBody.append("--").append(boundary).append("\r\n");
            multipartBody.append("Content-Type: text/plain; charset=UTF-8\r\n\r\n");
            multipartBody.append(content);
            multipartBody.append("\r\n--").append(boundary).append("--\r\n");
            
            HttpEntity<String> entity = new HttpEntity<>(multipartBody.toString(), headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                DRIVE_API_BASE + "/files?uploadType=multipart",
                HttpMethod.POST, entity, Map.class
            );
            
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("Failed to create file: " + e.getMessage());
        }
    }
    
    public Map<String, Object> shareFile(String accessToken, String fileId, String emailAddress) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> permission = Map.of(
                "type", "user",
                "role", "reader",
                "emailAddress", emailAddress
            );

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(permission, headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                DRIVE_API_BASE + "/files/" + fileId + "/permissions",
                HttpMethod.POST, entity, Map.class
            );
            
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("Failed to share file: " + e.getMessage());
        }
    }
    
    public Map<String, Object> createGoogleForm(String accessToken, Map<String, Object> formData) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);
            
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(formData, headers);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                FORMS_API_BASE + "/forms",
                HttpMethod.POST, entity, Map.class
            );
            
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("Failed to create Google Form: " + e.getMessage());
        }
    }
}