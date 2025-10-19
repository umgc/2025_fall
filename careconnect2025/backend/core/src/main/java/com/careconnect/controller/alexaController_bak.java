package com.careconnect.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import java.util.*;

@RestController
@RequestMapping("/alexaBak")
public class alexaController_bak {

    // ==============================
    // 🔒 1. Hardcoded token (for testing)
    // ==============================
    private static final String AUTH_TOKEN = "eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJjYXJlY29ubmVjdCIsInN1YiI6ImVsaXphYmV0aC5zYW50aWFnb2xld2lzQGdtYWlsLmNvbSIsInJvbGUiOiJQQVRJRU5UIiwiaWF0IjoxNzYwNTc3Nzc5LCJleHAiOjE3NjA1ODg1Nzl9.KwfH6_nRGriiVzjA1NPYXWV_Fva9GWZAIZcOjdqyHio";
    // Temporary dev token — replace when using real authentication

    // ==============================
    // 🌐 2. Inject task v2 URL
    // ==============================
    //@Value("${careconnect.api.base-url}")
    private String baseUrl = "http://localhost:8080/v2/api/tasks";

    // ==============================
    // 🧍‍♀️ 3. Hardcoded patient ID (for testing)
    // ==============================
    private static final int TEST_PATIENT_ID = 5;
    // Change this ID to fetch a different patient’s tasks

    // ==============================
    // 🔧 4. Helper method for headers
    // ==============================
    private HttpHeaders createAuthHeaders() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + AUTH_TOKEN);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    // ==============================
    // 🧠 5. Demo in-memory reminders
    // ==============================
    private final List<String> reminders = new ArrayList<>(List.of(
            "Appointment at 9 A.M.",
            "Meds ready",
            "Test Appointment"));

    @GetMapping("/calendarReminders")
    public List<String> getReminders() {
        return reminders;
    }

    @PostMapping("/calendarReminders")
    public Map<String, Object> addReminder(@RequestBody Map<String, String> request) {
        String reminderText = request.get("reminder");

        if (reminderText != null && !reminderText.trim().isEmpty()) {
            reminders.add(reminderText);
            return Map.of(
                    "success", true,
                    "message", "Reminder added successfully",
                    "reminder", reminderText);
        } else {
            return Map.of(
                    "success", false,
                    "message", "Reminder text cannot be empty");
        }
    }

    // ==============================
    // 📅 6. Fetch calendar tasks from CareConnect
    // ==============================
    @GetMapping("/calendarTasks")
    public ResponseEntity<?> getCalendarTasks() {
        // Use the injected task URL
        String careConnectUrl = String.format("%s/patient/%d", baseUrl, TEST_PATIENT_ID);

        RestTemplate restTemplate = new RestTemplate();
        HttpEntity<String> entity = new HttpEntity<>(null, createAuthHeaders());

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    careConnectUrl,
                    HttpMethod.GET,
                    entity,
                    String.class);
            return ResponseEntity.ok(response.getBody());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error fetching tasks: " + e.getMessage());
        }
    }

    // ==============================
    // 🆕 7. Add new calendar task (proxy to CareConnect V2)
    // ==============================
    @PostMapping("/calendarTasks")
    public ResponseEntity<?> addCalendarTask(@RequestBody Map<String, Object> taskRequest) {
        // CareConnect expects a POST to: /v2/api/tasks/patient/{id}
        String careConnectUrl = String.format("%s/patient/%d", baseUrl, TEST_PATIENT_ID);
    
        try {
            // ✅ 1. Ensure essential fields are always present
            taskRequest.put("patientId", TEST_PATIENT_ID);
    
            // Force-safe defaults (for testing)
            taskRequest.put("daysOfWeek", new ArrayList<>()); // Avoid DB constraint issues
            taskRequest.put("taskType", "TASK"); // Always override
            taskRequest.putIfAbsent("isCompleted", false);
    
            // ✅ 2. Handle optional description field
            Object description = taskRequest.get("description");
            if (description == null || description.toString().trim().isEmpty()) {
                taskRequest.put("description", null);
            }
    
            // ✅ 3. Log the final JSON being sent
            System.out.println("📦 Alexa → CareConnect task payload: " + taskRequest);
    
            // ✅ 4. Forward to real CareConnect API
            RestTemplate restTemplate = new RestTemplate();
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(taskRequest, createAuthHeaders());
    
            ResponseEntity<String> response = restTemplate.exchange(
                    careConnectUrl,
                    HttpMethod.POST,
                    entity,
                    String.class
            );
    
            // ✅ 5. Forward CareConnect’s response
            return ResponseEntity.status(response.getStatusCode()).body(response.getBody());
    
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(
                            "error", "❌ Error creating task",
                            "details", e.getMessage()
                    ));
        }
    }
    

}
