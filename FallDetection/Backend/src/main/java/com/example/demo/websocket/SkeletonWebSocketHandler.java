package com.example.demo.websocket;

import com.example.demo.service.AltumViewService;
import com.example.demo.dto.MqttCredentials;
import com.example.demo.dto.StreamToken;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hivemq.client.mqtt.MqttClient;
import com.hivemq.client.mqtt.mqtt3.Mqtt3AsyncClient;
import com.hivemq.client.mqtt.mqtt3.message.publish.Mqtt3Publish;
import com.hivemq.client.mqtt.datatypes.MqttQos;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Component
public class SkeletonWebSocketHandler extends TextWebSocketHandler {
    
    private static final Logger logger = LoggerFactory.getLogger(SkeletonWebSocketHandler.class);
    
    private final AltumViewService altumViewService;
    private final ObjectMapper objectMapper;
    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();
    private final Map<String, Mqtt3AsyncClient> mqttClients = new ConcurrentHashMap<>();
    private final Map<String, ScheduledExecutorService> tokenRefreshers = new ConcurrentHashMap<>();
    
    public SkeletonWebSocketHandler(AltumViewService altumViewService) {
        this.altumViewService = altumViewService;
        this.objectMapper = new ObjectMapper();
    }
    
    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.put(session.getId(), session);
        logger.info("WebSocket connected: {}", session.getId());
    }
    
    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        try {
            JsonNode msg = objectMapper.readTree(message.getPayload());
            String action = msg.get("action").asText();
            
            if ("connect".equals(action)) {
                String cameraSerialNumber = msg.get("cameraSerialNumber").asText();
                connectToMqtt(session, cameraSerialNumber);
            } else if ("disconnect".equals(action)) {
                disconnectFromMqtt(session.getId());
            }
        } catch (Exception e) {
            logger.error("Error handling WebSocket message", e);
            sendError(session, "Error: " + e.getMessage());
        }
    }
    
    private void connectToMqtt(WebSocketSession session, String cameraSerialNumber) {
        try {
            // Get MQTT credentials and stream token
            MqttCredentials credentials = altumViewService.getMqttCredentials();
            
            // Find camera by serial number to get its ID
            Long cameraId = altumViewService.getCameras().stream()
                .filter(camera -> camera.getSerialNumber().equals(cameraSerialNumber))
                .findFirst()
                .map(camera -> camera.getId())
                .orElseThrow(() -> new RuntimeException("Camera not found: " + cameraSerialNumber));
            
            StreamToken streamToken = altumViewService.getStreamToken(cameraId);
            Long groupId = altumViewService.getGroupId();
            
            logger.info("Connecting to MQTT for camera {} (ID: {}) on session {}", 
                cameraSerialNumber, cameraId, session.getId());
            
            // Build MQTT topics
            String publishTopic = String.format("mobile/%d/camera/%s/token/mobileStreamToken",
                groupId, cameraSerialNumber);
            String subscribeTopic = String.format("mobileClient/%d/camera/%s/skeleton/%d",
                groupId, cameraSerialNumber, streamToken.getStreamToken());
            
            // Parse WebSocket URL
            String wssUrl = credentials.getWssUrl();  // wss://prod.altumview.com:8084/mqtt
            URI uri = new URI(wssUrl);
            String host = uri.getHost();
            int port = uri.getPort();
            String path = uri.getPath();  // /mqtt
            
            logger.info("Connecting to MQTT broker: {}:{}{}", host, port, path);
            
            // Create HiveMQ MQTT client with WebSocket support
            String clientId = "backend_" + session.getId().substring(0, 8);
            Mqtt3AsyncClient mqttClient = MqttClient.builder()
                .useMqttVersion3()
                .identifier(clientId)
                .serverHost(host)
                .serverPort(port)
                .webSocketConfig()
                    .serverPath(path)
                    .applyWebSocketConfig()
                .sslWithDefaultConfig()
                .buildAsync();
            
            // Connect to MQTT broker
            mqttClient.connectWith()
                .simpleAuth()
                    .username(credentials.getUsername())
                    .password(credentials.getPasscode().getBytes(StandardCharsets.UTF_8))
                    .applySimpleAuth()
                .send()
                .whenComplete((connAck, throwable) -> {
                    if (throwable != null) {
                        logger.error("MQTT connection failed", throwable);
                        sendError(session, "MQTT connection failed: " + throwable.getMessage());
                        return;
                    }
                    
                    logger.info("MQTT connected for session {}", session.getId());
                    
                    // Subscribe to skeleton data topic
                    mqttClient.subscribeWith()
                        .topicFilter(subscribeTopic)
                        .qos(MqttQos.AT_MOST_ONCE)
                        .callback(publish -> {
                            try {
                                // Forward binary message to WebSocket client as base64
                                byte[] payload = publish.getPayloadAsBytes();
                                String base64Data = Base64.getEncoder().encodeToString(payload);
                                
                                if (session.isOpen()) {
                                    session.sendMessage(new TextMessage(objectMapper.writeValueAsString(
                                        Map.of(
                                            "type", "skeleton_data",
                                            "data", base64Data
                                        )
                                    )));
                                }
                            } catch (Exception e) {
                                logger.error("Error forwarding MQTT message", e);
                            }
                        })
                        .send()
                        .whenComplete((subAck, subThrowable) -> {
                            if (subThrowable != null) {
                                logger.error("MQTT subscription failed", subThrowable);
                                sendError(session, "MQTT subscription failed");
                                return;
                            }
                            
                            logger.info("Subscribed to topic: {}", subscribeTopic);
                            
                            // Publish initial stream token
                            publishStreamToken(mqttClient, streamToken, publishTopic);
                            
                            // Send success message
                            try {
                                session.sendMessage(new TextMessage(objectMapper.writeValueAsString(
                                    Map.of("type", "connected", "camera", cameraSerialNumber)
                                )));
                            } catch (Exception e) {
                                logger.error("Error sending success message", e);
                            }
                        });
                });
            
            // Schedule token refresh every 45 seconds
            ScheduledExecutorService scheduler = Executors.newSingleThreadScheduledExecutor();
            scheduler.scheduleAtFixedRate(() -> {
                try {
                    StreamToken newToken = altumViewService.getStreamToken(cameraId);
                    publishStreamToken(mqttClient, newToken, publishTopic);
                    logger.debug("Refreshed stream token for session {}", session.getId());
                } catch (Exception e) {
                    logger.error("Error refreshing stream token", e);
                }
            }, 45, 45, TimeUnit.SECONDS);
            
            // Store references
            mqttClients.put(session.getId(), mqttClient);
            tokenRefreshers.put(session.getId(), scheduler);
            
        } catch (Exception e) {
            logger.error("Error connecting to MQTT", e);
            sendError(session, "Failed to connect: " + e.getMessage());
        }
    }
    
    private void publishStreamToken(Mqtt3AsyncClient mqttClient, StreamToken streamToken, String publishTopic) {
        try {
            String tokenString = String.valueOf(streamToken.getStreamToken());
            mqttClient.publishWith()
                .topic(publishTopic)
                .payload(tokenString.getBytes(StandardCharsets.UTF_8))
                .qos(MqttQos.AT_MOST_ONCE)
                .send();
            logger.debug("Published stream token to topic: {}", publishTopic);
        } catch (Exception e) {
            logger.error("Error publishing stream token", e);
        }
    }
    
    private void disconnectFromMqtt(String sessionId) {
        try {
            // Stop token refresher
            ScheduledExecutorService scheduler = tokenRefreshers.remove(sessionId);
            if (scheduler != null) {
                scheduler.shutdown();
            }
            
            // Disconnect MQTT client
            Mqtt3AsyncClient mqttClient = mqttClients.remove(sessionId);
            if (mqttClient != null) {
                mqttClient.disconnect().whenComplete((v, throwable) -> {
                    if (throwable == null) {
                        logger.info("MQTT disconnected for session {}", sessionId);
                    } else {
                        logger.warn("Error disconnecting MQTT", throwable);
                    }
                });
            }
        } catch (Exception e) {
            logger.error("Error disconnecting MQTT", e);
        }
    }
    
    private void sendError(WebSocketSession session, String error) {
        try {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(objectMapper.writeValueAsString(
                    Map.of("type", "error", "message", error)
                )));
            }
        } catch (Exception e) {
            logger.error("Error sending error message", e);
        }
    }
    
    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        String sessionId = session.getId();
        disconnectFromMqtt(sessionId);
        sessions.remove(sessionId);
        logger.info("WebSocket disconnected: {}", sessionId);
    }
    
    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        logger.error("WebSocket transport error for session {}", session.getId(), exception);
        disconnectFromMqtt(session.getId());
    }
}
