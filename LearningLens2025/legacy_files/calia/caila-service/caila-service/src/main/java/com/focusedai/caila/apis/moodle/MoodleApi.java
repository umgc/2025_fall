package com.focusedai.caila.apis.moodle;

import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import lombok.RequiredArgsConstructor;
import java.util.*;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
@RequiredArgsConstructor
public class MoodleApi {
    private final RestTemplate restTemplate;
    
    public Map<String, Object> createNote(String moodleUrl, String webServiceToken, 
                                         String userId, String courseId, String content) {
        try {
            String url = moodleUrl + "/webservice/rest/server.php";
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            
            StringBuilder requestBody = new StringBuilder();
            requestBody.append("wstoken=").append(webServiceToken);
            requestBody.append("&wsfunction=core_notes_create_notes");
            requestBody.append("&moodlewsrestformat=json");
            requestBody.append("&notes[0][userid]=").append(userId);
            requestBody.append("&notes[0][publishstate]=course");
            requestBody.append("&notes[0][courseid]=").append(courseId);
            requestBody.append("&notes[0][text]=").append(URLEncoder.encode(content, StandardCharsets.UTF_8));
            requestBody.append("&notes[0][format]=1");
            
            HttpEntity<String> request = new HttpEntity<>(requestBody.toString(), headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);
            
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("Failed to create note: " + e.getMessage());
        }
    }
    
    public List<Map<String, Object>> getCourseNotes(String moodleUrl, String webServiceToken, 
                                                   String courseId, String userId) {
        try {
            String url = moodleUrl + "/webservice/rest/server.php"
                    + "?wstoken=" + webServiceToken
                    + "&wsfunction=core_notes_get_course_notes"
                    + "&courseid=" + courseId
                    + "&userid=" + userId
                    + "&moodlewsrestformat=json";
            
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
            Map<String, Object> responseBody = response.getBody();
            
            List<Map<String, Object>> allNotes = new ArrayList<>();
            if (responseBody != null) {
                List<Map<String, Object>> personalNotes = (List<Map<String, Object>>) responseBody.get("personalnotes");
                List<Map<String, Object>> courseNotes = (List<Map<String, Object>>) responseBody.get("coursenotes");
                List<Map<String, Object>> siteNotes = (List<Map<String, Object>>) responseBody.get("sitenotes");
                
                if (personalNotes != null) allNotes.addAll(personalNotes);
                if (courseNotes != null) allNotes.addAll(courseNotes);
                if (siteNotes != null) allNotes.addAll(siteNotes);
            }
            
            return allNotes;
        } catch (Exception e) {
            throw new RuntimeException("Failed to get course notes: " + e.getMessage());
        }
    }
}