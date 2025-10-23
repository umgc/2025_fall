package com.careconnect.config;

import com.careconnect.websocket.CallNotificationHandler;
import com.careconnect.websocket.CareConnectWebSocketHandler;
import com.careconnect.websocket.NotificationWebSocketHandler;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * WebSocket Configuration
 *
 * This configuration is profile-aware:
 * - Local Development (dev profile): Enables Spring WebSocket for real-time connections
 * - Production (prod profile): Disabled - Uses AWS API Gateway WebSocket instead
 *
 * Configuration is controlled by:
 * - careconnect.websocket.enabled: Enable/disable WebSocket support
 * - careconnect.websocket.mode: "local" for Spring WebSocket, "aws" for API Gateway
 */
@Slf4j
@Configuration
@ConditionalOnProperty(name = "careconnect.websocket.enabled", havingValue = "true", matchIfMissing = true)
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Autowired
    private CallNotificationHandler callNotificationHandler;

    @Autowired
    private CareConnectWebSocketHandler careConnectWebSocketHandler;

    @Autowired
    private NotificationWebSocketHandler notificationWebSocketHandler;

    @Value("${careconnect.websocket.endpoint:/ws/careconnect}")
    private String careConnectEndpoint;

    @Value("${careconnect.websocket.allowed-origins:*}")
    private String allowedOrigins;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        log.info("Registering WebSocket handlers for local development mode");
        log.info("CareConnect WebSocket endpoint: {}", careConnectEndpoint);
        log.info("Allowed origins: {}", allowedOrigins);

        // Call/SMS notification WebSocket endpoint
        registry.addHandler(callNotificationHandler, "/ws/calls")
                .setAllowedOrigins(allowedOrigins)
                .withSockJS();

        // General CareConnect WebSocket endpoint for real-time updates
        registry.addHandler(careConnectWebSocketHandler, careConnectEndpoint)
                .setAllowedOrigins(allowedOrigins)
                .withSockJS();

        // Notification WebSocket endpoint (no SockJS fallback)
        registry.addHandler(notificationWebSocketHandler, "/ws/notifications")
                .setAllowedOrigins(allowedOrigins);

        log.info("WebSocket handlers registered successfully in LOCAL mode");
    }
}