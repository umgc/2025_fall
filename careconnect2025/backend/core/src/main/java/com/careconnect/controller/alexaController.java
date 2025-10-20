package com.careconnect.controller;

import com.careconnect.security.JwtTokenProvider;
import com.careconnect.model.Patient;
import com.careconnect.model.User;
import com.careconnect.repository.UserRepository;
import com.careconnect.repository.PatientRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@RestController
@RequestMapping("/alexa")
public class AlexaController {

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PatientRepository patientRepository;

    // @Value("${careconnect.api.base-url:http://localhost:8080/v2/api/tasks}")
    private String baseUrl = "http://localhost:8080/v2/api/tasks";

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper mapper = new ObjectMapper();

    // ==============================================================
    // 🔧 Helper: Unlink Alexa account for a patient
    // ==============================================================
    private void unlinkAlexaAccount(Long patientId, String reason) {
        try {
            Optional<Patient> patientOpt = patientRepository.findById(patientId);
            if (patientOpt.isPresent()) {
                Patient patient = patientOpt.get();
                patient.setAlexaLinked(false);
                patientRepository.save(patient);
                System.out.println("🔓 Unlinked Alexa for patient ID " + patientId + ". Reason: " + reason);
            }
        } catch (Exception e) {
            System.err.println("⚠️ Failed to unlink Alexa account: " + e.getMessage());
        }
    }

    // ==============================================================
    // 🔧 Helper: Extract token from Alexa request payload
    // ==============================================================
    private String extractAlexaToken(String requestBody) {
        try {
            JsonNode root = mapper.readTree(requestBody);

            // Custom skill
            if (root.has("session") && root.path("session").path("user").has("accessToken")) {
                return root.path("session").path("user").path("accessToken").asText();
            }

            // Smart Home
            if (root.has("directive")) {
                return root.path("directive").path("endpoint")
                        .path("scope").path("token").asText(null);
            }

            return null;
        } catch (Exception e) {
            System.err.println("⚠️ Failed to extract Alexa token: " + e.getMessage());
            return null;
        }
    }

    // ==============================================================
    // 🔧 Helper: Build Authorization header
    // ==============================================================
    private HttpHeaders createAuthHeaders(String token) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }

    // ==============================================================
    // 🧠 Helper: Resolve patient ID from JWT → DB lookup
    // ==============================================================
    private Long resolvePatientIdFromToken(String token) {
        try {
            String email = jwtTokenProvider.getEmailFromToken(token);
            if (email == null) {
                System.err.println("⚠️ Token missing email claim");
                return null;
            }

            Optional<User> userOpt = userRepository.findByEmail(email);
            if (userOpt.isEmpty()) {
                System.err.println("⚠️ No user found for email: " + email);
                return null;
            }

            User user = userOpt.get();
            System.out.println(
                    "👤 Found user: " + user.getEmail() + " (id=" + user.getId() + ", role=" + user.getRole() + ")");

            // 🧩 CASE 1 — Direct Patient Login
            if (user.getRole() == com.careconnect.security.Role.PATIENT) {
                Optional<Patient> patientOpt = patientRepository.findByUser(user);
                if (patientOpt.isPresent()) {
                    Long patientId = patientOpt.get().getId();
                    System.out.println("🩺 Found patient ID " + patientId + " linked to user " + user.getEmail());
                    return patientId;
                } else {
                    System.err.println("⚠️ No Patient record linked to this user (role=PATIENT).");
                    return null;
                }
            }

            // 🧩 CASE 2 — Caregiver Login (linked via CaregiverPatientLink)
            else if (user.getRole() == com.careconnect.security.Role.CAREGIVER) {
                System.out.println("🧑‍⚕️ User is a caregiver — attempting to find linked patient(s)");

                List<Patient> allPatients = patientRepository.findAll();
                for (Patient p : allPatients) {
                    boolean hasAccess = patientRepository.hasAccessByCaregiverId(p.getId(), user.getId());
                    if (hasAccess) {
                        System.out.println("✅ Caregiver " + user.getEmail() + " has access to patient ID " + p.getId());
                        return p.getId();
                    }
                }

                System.err.println("⚠️ Caregiver " + user.getEmail() + " has no active linked patients.");
                return null;
            }

            // 🧩 CASE 3 — Unsupported Role
            else {
                System.err.println("⚠️ Unsupported role type: " + user.getRole());
                return null;
            }

        } catch (Exception e) {
            System.err.println("💥 Failed to resolve patient ID: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }

    // ==============================================================
    // 📅 1️⃣ Get CareConnect Tasks (authenticated)
    // ==============================================================
    @PostMapping("/calendarTasks")
    public ResponseEntity<?> getCalendarTasks(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) Map<String, Object> alexaBody) {
        Long patientId = null;
        try {
            // 🧩 1. Extract token (from header or Alexa payload)
            String token = null;

            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                token = authHeader.substring(7);
            } else if (alexaBody != null && alexaBody.containsKey("accessToken")) {
                token = (String) alexaBody.get("accessToken");
            } else if (alexaBody != null) {
                String raw = new ObjectMapper().writeValueAsString(alexaBody);
                token = extractAlexaToken(raw);
            }

            // 🚨 UNLINK CASE 1: Invalid or expired token
            if (token == null || !jwtTokenProvider.validateToken(token)) {
                System.err.println("🔓 Token validation failed - potential expired/revoked token");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Invalid or missing access token"));
            }

            // 🧩 2. Resolve patient ID from JWT → DB lookup
            patientId = resolvePatientIdFromToken(token);
            
            // 🚨 UNLINK CASE 2: Unable to resolve patient (user deleted, role changed, etc.)
            if (patientId == null) {
                System.err.println("🔓 Unable to resolve patient ID - user may have been deleted or role changed");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("error", "Unable to determine patient ID"));
            }

            // 🧩 3. Forward to CareConnect backend
            String url = String.format("%s/patient/%d", baseUrl, patientId);
            HttpEntity<String> entity = new HttpEntity<>(null, createAuthHeaders(token));

            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
            System.out.println("🧾 [CareConnect API] Status: " + response.getStatusCode());
            System.out.println("🧾 [CareConnect API] Body: " + response.getBody());
            
            // 🚨 UNLINK CASE 3: Forbidden - user no longer has access to this patient
            if (response.getStatusCode() == HttpStatus.FORBIDDEN) {
                unlinkAlexaAccount(patientId, "Access forbidden - user no longer authorized for this patient");
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Access denied to patient data"));
            }
            
            // 🚨 UNLINK CASE 4: Unauthorized from backend - token rejected by backend
            if (response.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                unlinkAlexaAccount(patientId, "Backend rejected token - authentication failed");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Authentication failed"));
            }

            // 🧩 4. Return tasks from CareConnect API
            return ResponseEntity.status(response.getStatusCode()).body(response.getBody());

        } catch (org.springframework.web.client.HttpClientErrorException ex) {
            // 🚨 UNLINK CASE 5: Handle HTTP 401/403 exceptions from backend
            if (ex.getStatusCode() == HttpStatus.UNAUTHORIZED || ex.getStatusCode() == HttpStatus.FORBIDDEN) {
                if (patientId != null) {
                    unlinkAlexaAccount(patientId, "Backend authentication/authorization error: " + ex.getStatusCode());
                }
                return ResponseEntity.status(ex.getStatusCode())
                        .body(Map.of("error", "Authentication or authorization failed"));
            }
            
            // Network/connectivity issues - don't unlink
            ex.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error fetching tasks", "details", ex.getMessage()));
                    
        } catch (Exception e) {
            // Network/connectivity issues - don't unlink
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error fetching tasks", "details", e.getMessage()));
        }
    }

    // ==============================================================
    // 🆕 2️⃣ Add New CareConnect Task (authenticated)
    // ==============================================================
    @PostMapping("/calendarTasks/add")
    public ResponseEntity<?> addCalendarTask(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody Map<String, Object> alexaBody) {
        Long patientId = null;
        try {
            String token = null;

            // 1️⃣ Prefer Authorization header
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                token = authHeader.substring(7);
            }
            // 2️⃣ Fallback to JSON field if present
            else if (alexaBody.containsKey("accessToken")) {
                token = (String) alexaBody.get("accessToken");
            }

            // 🚨 UNLINK CASE 1: Invalid or expired token
            if (token == null || !jwtTokenProvider.validateToken(token)) {
                System.err.println("🔓 Token validation failed for task creation");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Missing or invalid access token"));
            }

            patientId = resolvePatientIdFromToken(token);
            
            // 🚨 UNLINK CASE 2: Unable to resolve patient
            if (patientId == null) {
                System.err.println("🔓 Unable to resolve patient ID for task creation");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(Map.of("error", "Unable to resolve patient ID"));
            }

            // Build CareConnect request
            String url = String.format("%s/patient/%d", baseUrl, patientId);
            alexaBody.put("patientId", patientId);
            alexaBody.put("taskType", "TASK");
            alexaBody.putIfAbsent("isCompleted", false);
            alexaBody.putIfAbsent("daysOfWeek", new ArrayList<>());

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(alexaBody, createAuthHeaders(token));
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.POST, entity, String.class);

            // 🚨 UNLINK CASE 3: Forbidden - user no longer has access
            if (response.getStatusCode() == HttpStatus.FORBIDDEN) {
                unlinkAlexaAccount(patientId, "Access forbidden during task creation");
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(Map.of("error", "Access denied to patient data"));
            }
            
            // 🚨 UNLINK CASE 4: Unauthorized from backend
            if (response.getStatusCode() == HttpStatus.UNAUTHORIZED) {
                unlinkAlexaAccount(patientId, "Backend rejected token during task creation");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(Map.of("error", "Authentication failed"));
            }

            return ResponseEntity.status(response.getStatusCode()).body(response.getBody());
            
        } catch (org.springframework.web.client.HttpClientErrorException ex) {
            // 🚨 UNLINK CASE 5: Handle HTTP 401/403 exceptions from backend
            if (ex.getStatusCode() == HttpStatus.UNAUTHORIZED || ex.getStatusCode() == HttpStatus.FORBIDDEN) {
                if (patientId != null) {
                    unlinkAlexaAccount(patientId, "Backend auth error during task creation: " + ex.getStatusCode());
                }
                return ResponseEntity.status(ex.getStatusCode())
                        .body(Map.of("error", "Authentication or authorization failed"));
            }
            
            // Network/connectivity issues - don't unlink
            ex.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error adding task", "details", ex.getMessage()));
                    
        } catch (Exception e) {
            // Network/connectivity issues - don't unlink
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Error adding task", "details", e.getMessage()));
        }
    }
}