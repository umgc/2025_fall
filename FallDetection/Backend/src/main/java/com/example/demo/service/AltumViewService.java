package com.example.demo.service;

import com.example.demo.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Service
@Slf4j
public class AltumViewService {
    
    private final RestTemplate restTemplate;
    
    @Value("${altumview.oauth-url}")
    private String oauthUrl;
    
    @Value("${altumview.api-url}")
    private String apiUrl;
    
    @Value("${altumview.client-id}")
    private String clientId;
    
    @Value("${altumview.client-secret}")
    private String clientSecret;
    
    @Value("${altumview.scope}")
    private String scope;
    
    private String cachedAccessToken;
    private Long tokenExpiresAt;
    
    public AltumViewService() {
        this.restTemplate = new RestTemplate();
        // Add logging interceptor to debug the request
        this.restTemplate.getInterceptors().add((request, body, execution) -> {
            log.debug("Request URI: {}", request.getURI());
            log.debug("Request Method: {}", request.getMethod());
            log.debug("Request Headers: {}", request.getHeaders());
            log.debug("Request Body: {}", new String(body));
            return execution.execute(request, body);
        });
    }
    
    /**
     * Get OAuth access token - FIXED VERSION using RestTemplate with manual form encoding
     */
    public String getAccessToken() {
        // Return cached token if still valid
        if (cachedAccessToken != null && tokenExpiresAt != null) {
            long now = System.currentTimeMillis() / 1000;
            if (now < tokenExpiresAt - 300) {
                log.info("Using cached access token");
                return cachedAccessToken;
            }
        }
        
        try {
            log.info("Requesting new access token from {}", oauthUrl + "/token");
            
            // Manually build URL-encoded form data
            String formData = String.format(
                "grant_type=%s&client_id=%s&client_secret=%s&scope=%s",
                java.net.URLEncoder.encode("client_credentials", "UTF-8"),
                java.net.URLEncoder.encode(clientId, "UTF-8"),
                java.net.URLEncoder.encode(clientSecret, "UTF-8"),
                java.net.URLEncoder.encode(scope, "UTF-8")
            );
            
            // Set headers
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.set("Accept", "application/json");
            
            // Create request entity with String body
            HttpEntity<String> request = new HttpEntity<>(formData, headers);
            
            log.debug("Form data: {}", formData);
            log.debug("Headers: {}", headers);
            
            // Make POST request
            ResponseEntity<TokenResponse> response = restTemplate.postForEntity(
                oauthUrl + "/token",
                request,
                TokenResponse.class
            );
            
            TokenResponse tokenResponse = response.getBody();
            
            if (tokenResponse != null && tokenResponse.getAccessToken() != null) {
                cachedAccessToken = tokenResponse.getAccessToken();
                long now = System.currentTimeMillis() / 1000;
                tokenExpiresAt = now + tokenResponse.getExpiresIn();
                log.info("✓ Obtained new access token, expires in {} seconds", tokenResponse.getExpiresIn());
                return cachedAccessToken;
            }
            
            throw new RuntimeException("Failed to obtain access token: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error obtaining access token: {}", e.getMessage());
            throw new RuntimeException("Failed to obtain access token: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get MQTT credentials
     */
    public MqttCredentials getMqttCredentials() {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/mqttAccount",
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                Map<String, Object> mqttAccount = (Map<String, Object>) data.get("mqtt_account");
                
                MqttCredentials credentials = new MqttCredentials();
                credentials.setUsername((String) mqttAccount.get("username"));
                credentials.setPasscode((String) mqttAccount.get("passcode"));
                credentials.setWssUrl((String) data.get("wss_url"));
                credentials.setExpiresAt(((Number) mqttAccount.get("expires_at")).longValue());
                credentials.setExpiresIn((Integer) mqttAccount.get("expires_in"));
                
                log.info("✓ Retrieved MQTT credentials");
                return credentials;
            }
            
            throw new RuntimeException("Failed to get MQTT credentials: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error getting MQTT credentials: {}", e.getMessage());
            throw new RuntimeException("Failed to get MQTT credentials: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get list of cameras
     */
    public List<Camera> getCameras() {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/cameras",
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                Map<String, Object> cameras = (Map<String, Object>) data.get("cameras");
                List<Map<String, Object>> array = (List<Map<String, Object>>) cameras.get("array");
                
                List<Camera> cameraList = array.stream()
                    .map(this::mapToCamera)
                    .toList();
                
                log.info("✓ Retrieved {} cameras", cameraList.size());
                return cameraList;
            }
            
            throw new RuntimeException("Failed to get cameras: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error getting cameras: {}", e.getMessage());
            throw new RuntimeException("Failed to get cameras: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get stream token for a camera
     */
    public StreamToken getStreamToken(Long cameraId) {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/cameras/" + cameraId + "/streamtoken",
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                
                StreamToken streamToken = new StreamToken();
                streamToken.setStreamToken(((Number) data.get("stream_token")).longValue());
                streamToken.setExpiresAt(((Number) data.get("expires_at")).longValue());
                streamToken.setExpiresIn((Integer) data.get("expires_in"));
                
                log.info("✓ Retrieved stream token for camera {}", cameraId);
                return streamToken;
            }
            
            throw new RuntimeException("Failed to get stream token: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error getting stream token: {}", e.getMessage());
            throw new RuntimeException("Failed to get stream token: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get preview token for a camera
     * Used for accessing camera view/snapshot images
     */
    public PreviewToken getPreviewToken(Long cameraId) {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/cameras/" + cameraId + "/previewtoken",
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                
                PreviewToken previewToken = new PreviewToken();
                previewToken.setPreviewToken(((Number) data.get("preview_token")).longValue());
                previewToken.setExpiresAt(((Number) data.get("expires_at")).longValue());
                previewToken.setExpiresIn((Integer) data.get("expires_in"));
                
                log.info("✓ Retrieved preview token for camera {}", cameraId);
                return previewToken;
            }
            
            throw new RuntimeException("Failed to get preview token: no data in response");
            
        } catch (Exception e) {
            log.error("✗ Error getting preview token: {}", e.getMessage());
            throw new RuntimeException("Failed to get preview token: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get recent alerts
     */
    public List<Alert> getAlerts(int limit) {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/alerts?limit=" + limit,
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                
                // Alerts are nested under "alerts" -> "array"
                Map<String, Object> alerts = (Map<String, Object>) data.get("alerts");
                if (alerts == null) {
                    log.info("✓ Retrieved 0 alerts (no alerts object in response)");
                    return List.of();
                }
                
                List<Map<String, Object>> array = (List<Map<String, Object>>) alerts.get("array");
                
                // Handle null or empty array
                if (array == null || array.isEmpty()) {
                    log.info("✓ Retrieved 0 alerts (no alerts found)");
                    return List.of();
                }
                
                List<Alert> alertList = array.stream()
                    .map(this::mapToAlert)
                    .toList();
                
                log.info("✓ Retrieved {} alerts", alertList.size());
                return alertList;
            }
            
            throw new RuntimeException("Failed to get alerts: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error getting alerts: {}", e.getMessage());
            throw new RuntimeException("Failed to get alerts: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get alert by ID with skeleton data
     */
    public Alert getAlertById(String alertId) {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            log.info("Requesting alert {} from {}/alerts/{}", alertId, apiUrl, alertId);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/alerts/" + alertId,
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                
                // Alert data is nested under "alert" key
                Map<String, Object> alertData = (Map<String, Object>) data.get("alert");
                
                if (alertData == null) {
                    throw new RuntimeException("No alert data in response");
                }
                
                // Log skeleton_file presence and length
                Object skeletonFile = alertData.get("skeleton_file");
                if (skeletonFile != null) {
                    log.info("✓ Alert {} has skeleton_file (length: {} chars)", 
                        alertId, ((String) skeletonFile).length());
                } else {
                    log.warn("⚠ Alert {} has NO skeleton_file in response", alertId);
                }
                
                Alert alert = mapToAlert(alertData, alertId);
                log.info("✓ Successfully mapped alert {}", alertId);
                return alert;
            }
            
            throw new RuntimeException("Failed to get alert: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error getting alert {}: {}", alertId, e.getMessage(), e);
            throw new RuntimeException("Failed to get alert: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get fresh background image URL for an alert
     * This requests a new pre-signed S3 URL from AltumView
     * 
     * According to AltumView API docs:
     * GET /alerts/{alertId}/background
     * Returns: { "data": { "background_url": "https://..." } }
     */
    public String getAlertBackgroundUrl(String alertId) {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            log.info("Requesting fresh background URL for alert {}", alertId);
            
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/alerts/" + alertId + "/background",
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                String backgroundUrl = (String) data.get("background_url");
                
                if (backgroundUrl != null && !backgroundUrl.isEmpty()) {
                    log.info("✓ Retrieved fresh background URL for alert {}", alertId);
                    return backgroundUrl;
                }
            }
            
            throw new RuntimeException("No background URL available for alert");
            
        } catch (Exception e) {
            log.error("✗ Error getting alert background URL: {}", e.getMessage());
            throw new RuntimeException("Failed to get alert background URL: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get video clip URL for an alert
     * 
     * According to AltumView API docs:
     * GET /alerts/{alertId}/video or /alerts/{alertId}/clip
     * Returns: { "data": { "video_url": "https://..." } }
     */
    public String getAlertVideoUrl(String alertId) {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            log.info("Requesting video URL for alert {}", alertId);
            
            // Try /video endpoint first
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/alerts/" + alertId + "/video",
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                
                // Try different possible field names
                String videoUrl = (String) data.get("video_url");
                if (videoUrl == null) {
                    videoUrl = (String) data.get("clip_url");
                }
                if (videoUrl == null) {
                    videoUrl = (String) data.get("url");
                }
                
                if (videoUrl != null && !videoUrl.isEmpty()) {
                    log.info("✓ Retrieved video URL for alert {}", alertId);
                    return videoUrl;
                }
            }
            
            throw new RuntimeException("No video URL available for alert");
            
        } catch (Exception e) {
            log.error("✗ Error getting alert video URL: {}", e.getMessage());
            throw new RuntimeException("Failed to get alert video URL: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get complete skeleton stream configuration
     */
    public SkeletonStreamConfig getSkeletonStreamConfig(Long cameraId) {
        String token = getAccessToken();
        MqttCredentials mqtt = getMqttCredentials();
        Camera camera = getCameras().stream()
            .filter(c -> c.getId().equals(cameraId))
            .findFirst()
            .orElseThrow(() -> new RuntimeException("Camera not found"));
        StreamToken streamToken = getStreamToken(cameraId);
        
        // Get group ID from token response
        TokenResponse tokenResponse = getTokenResponse();
        Long groupId = tokenResponse.getData().getGroupId();
        
        // Build config
        SkeletonStreamConfig config = new SkeletonStreamConfig();
        config.setMqttUsername(mqtt.getUsername());
        config.setMqttPassword(mqtt.getPasscode());
        config.setWssUrl(mqtt.getWssUrl());
        config.setGroupId(groupId);
        config.setSerialNumber(camera.getSerialNumber());
        config.setStreamToken(streamToken.getStreamToken());
        
        // Build topics
        String publishTopic = String.format("mobile/%d/camera/%s/token/mobileStreamToken",
            groupId, camera.getSerialNumber());
        String subscribeTopic = String.format("mobileClient/%d/camera/%s/skeleton/%d",
            groupId, camera.getSerialNumber(), streamToken.getStreamToken());
        
        config.setPublishTopic(publishTopic);
        config.setSubscribeTopic(subscribeTopic);
        
        log.info("✓ Built complete skeleton stream config for camera {}", cameraId);
        return config;
    }
    
    // Helper methods
    private Camera mapToCamera(Map<String, Object> data) {
        Camera camera = new Camera();
        camera.setId(((Number) data.get("id")).longValue());
        camera.setSerialNumber((String) data.get("serial_number"));
        camera.setFriendlyName((String) data.get("friendly_name"));
        camera.setRoomName((String) data.get("room_name"));
        camera.setIsOnline((Boolean) data.get("is_online"));
        camera.setModel((String) data.get("model"));
        camera.setVersion((String) data.get("version"));
        return camera;
    }
    
    private Alert mapToAlert(Map<String, Object> data) {
        return mapToAlert(data, null);
    }
    
    private Alert mapToAlert(Map<String, Object> data, String providedAlertId) {
        Alert alert = new Alert();
        
        // API returns serial_number, but we also set it as camera_serial_number for compatibility
        String serialNumber = (String) data.get("serial_number");
        alert.setSerialNumber(serialNumber);
        alert.setCameraSerialNumber(serialNumber);
        
        // API returns unix_time, map it to createdAt
        Object unixTime = data.get("unix_time");
        if (unixTime != null) {
            alert.setCreatedAt(((Number) unixTime).longValue());
        }
        
        // Map other fields
        Object eventType = data.get("event_type");
        if (eventType != null) {
            alert.setEventType(((Number) eventType).intValue());
            // Map event_type to alert_type for compatibility
            alert.setAlertType("fall_detection"); // Default, adjust based on event_type if needed
        }
        
        alert.setPersonName((String) data.get("person_name"));
        alert.setRoomName((String) data.get("room_name"));
        alert.setCameraName((String) data.get("camera_name"));
        alert.setIsResolved((Boolean) data.get("is_resolved"));
        alert.setBackgroundUrl((String) data.get("background_url"));
        
        // Use provided alert ID if available, otherwise try to get from data or generate
        String id = providedAlertId;
        if (id == null) {
            id = (String) data.get("id");
        }
        if (id == null && serialNumber != null && unixTime != null) {
            id = serialNumber + "_" + unixTime;
        }
        alert.setId(id);
        
        // Handle skeleton_file - it comes as base64 string from API
        String skeletonFile = (String) data.get("skeleton_file");
        if (skeletonFile != null && !skeletonFile.isEmpty()) {
            log.debug("Mapping skeleton_file (length: {} chars)", skeletonFile.length());
            alert.setSkeletonFile(skeletonFile);
        } else {
            log.debug("No skeleton_file in alert data");
            alert.setSkeletonFile(null);
        }
        
        return alert;
    }
    
    /**
     * Get current view/snapshot from camera
     * Uses preview token parameter
     */
    public byte[] getCameraView(Long cameraId) {
        String token = getAccessToken();
        
        try {
            // Get preview token instead of stream token
            PreviewToken previewToken = getPreviewToken(cameraId);
            
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + token);
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            String url = apiUrl + "/cameras/" + cameraId + "/view?preview_token=" + previewToken.getPreviewToken();
            log.info("Requesting camera view from: {}", url);
            
            ResponseEntity<byte[]> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                entity,
                byte[].class
            );
            
            byte[] imageBytes = response.getBody();
            
            if (imageBytes != null && imageBytes.length > 0) {
                log.info("✓ Retrieved camera view for camera {}, size: {} bytes", cameraId, imageBytes.length);
                return imageBytes;
            }
            
            throw new RuntimeException("Failed to get camera view: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error getting camera view: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to get camera view: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get background image URL from camera
     * Returns the pre-signed S3 URL
     */
    public String getCameraBackgroundUrl(Long cameraId) {
        String token = getAccessToken();
        
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + token);
        HttpEntity<String> entity = new HttpEntity<>(headers);
        
        try {
            // Get the background URL from AltumView API
            ResponseEntity<Map> response = restTemplate.exchange(
                apiUrl + "/cameras/" + cameraId + "/background",
                HttpMethod.GET,
                entity,
                Map.class
            );
            
            Map<String, Object> body = response.getBody();
            
            if (body != null && body.containsKey("data")) {
                Map<String, Object> data = (Map<String, Object>) body.get("data");
                String backgroundUrl = (String) data.get("background_url");
                
                if (backgroundUrl != null && !backgroundUrl.isEmpty()) {
                    log.info("✓ Retrieved background URL for camera {}", cameraId);
                    return backgroundUrl;
                }
            }
            
            throw new RuntimeException("Failed to get camera background URL: empty response");
            
        } catch (Exception e) {
            log.error("✗ Error getting camera background URL: {}", e.getMessage());
            throw new RuntimeException("Failed to get camera background URL: " + e.getMessage(), e);
        }
    }

    /**
     * Get background image from camera
     * Fetches the image from S3 and returns as bytes to avoid CORS issues
     * Uses HttpURLConnection to avoid adding extra headers that break AWS signature
     */
    public byte[] getCameraBackground(Long cameraId) {
        // Get the S3 URL
        String backgroundUrl = getCameraBackgroundUrl(cameraId);
        
        try {
            // Use HttpURLConnection instead of RestTemplate to avoid extra headers
            java.net.URL url = new java.net.URL(backgroundUrl);
            java.net.HttpURLConnection connection = (java.net.HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setDoInput(true);
            
            // Don't add ANY extra headers - AWS signature depends on it
            int responseCode = connection.getResponseCode();
            
            if (responseCode == 200) {
                // Read the image bytes
                java.io.InputStream inputStream = connection.getInputStream();
                java.io.ByteArrayOutputStream buffer = new java.io.ByteArrayOutputStream();
                
                int nRead;
                byte[] data = new byte[8192];
                while ((nRead = inputStream.read(data, 0, data.length)) != -1) {
                    buffer.write(data, 0, nRead);
                }
                
                inputStream.close();
                byte[] imageBytes = buffer.toByteArray();
                
                log.info("✓ Retrieved camera background image for camera {}, size: {} bytes", cameraId, imageBytes.length);
                return imageBytes;
            } else {
                throw new RuntimeException("Failed to get camera background: HTTP " + responseCode);
            }
        } catch (Exception e) {
            log.error("✗ Error downloading camera background from S3: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to download camera background: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get background image from alert
     * Fetches the image from S3 and returns as bytes to avoid CORS issues
     * Uses HttpURLConnection to avoid adding extra headers that break AWS signature
     */
    public byte[] getAlertBackground(String alertId) {
        // Get the alert to extract background URL
        Alert alert = getAlertById(alertId);
        
        if (alert.getBackgroundUrl() == null || alert.getBackgroundUrl().isEmpty()) {
            throw new RuntimeException("No background URL available for alert " + alertId);
        }
        
        String backgroundUrl = alert.getBackgroundUrl();
        
        try {
            // Use HttpURLConnection instead of RestTemplate to avoid extra headers
            java.net.URL url = new java.net.URL(backgroundUrl);
            java.net.HttpURLConnection connection = (java.net.HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setDoInput(true);
            
            // Don't add ANY extra headers - AWS signature depends on it
            int responseCode = connection.getResponseCode();
            
            if (responseCode == 200) {
                // Read the image bytes
                java.io.InputStream inputStream = connection.getInputStream();
                java.io.ByteArrayOutputStream buffer = new java.io.ByteArrayOutputStream();
                
                int nRead;
                byte[] data = new byte[8192];
                while ((nRead = inputStream.read(data, 0, data.length)) != -1) {
                    buffer.write(data, 0, nRead);
                }
                
                inputStream.close();
                byte[] imageBytes = buffer.toByteArray();
                
                log.info("✓ Retrieved alert background image for alert {}, size: {} bytes", alertId, imageBytes.length);
                return imageBytes;
            } else {
                throw new RuntimeException("Failed to get alert background: HTTP " + responseCode);
            }
        } catch (Exception e) {
            log.error("✗ Error downloading alert background from S3: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to download alert background: " + e.getMessage(), e);
        }
    }
    
    /**
     * Get the group ID from the token response
     */
    public Long getGroupId() {
        TokenResponse tokenResponse = getTokenResponse();
        return tokenResponse.getData().getGroupId();
    }
    
    private TokenResponse getTokenResponse() {
        try {
            // Manually build URL-encoded form data
            String formData = String.format(
                "grant_type=%s&client_id=%s&client_secret=%s&scope=%s",
                java.net.URLEncoder.encode("client_credentials", "UTF-8"),
                java.net.URLEncoder.encode(clientId, "UTF-8"),
                java.net.URLEncoder.encode(clientSecret, "UTF-8"),
                java.net.URLEncoder.encode(scope, "UTF-8")
            );
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            headers.set("Accept", "application/json");
            
            HttpEntity<String> request = new HttpEntity<>(formData, headers);
            
            ResponseEntity<TokenResponse> response = restTemplate.postForEntity(
                oauthUrl + "/token",
                request,
                TokenResponse.class
            );
            
            return response.getBody();
        } catch (Exception e) {
            throw new RuntimeException("Failed to get token response: " + e.getMessage(), e);
        }
    }
}