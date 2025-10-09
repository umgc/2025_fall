package com.careconnect.config;

import com.careconnect.websocket.CallNotificationHandler;
import com.careconnect.websocket.CareConnectWebSocketHandler;
import com.careconnect.websocket.NotificationWebSocketHandler;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
// Cannot work on AWS Lambda now. We will use profile make it dynamic for local test vs lambda deployments.
//@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    // Commented out to prevent bean injection errors when WebSocket is disabled for Lambda
    // @Autowired
    // private CallNotificationHandler callNotificationHandler;

    // @Autowired
    // private CareConnectWebSocketHandler careConnectWebSocketHandler;

    // @Autowired
    // private NotificationWebSocketHandler notificationWebSocketHandler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // WebSocket handlers disabled for Lambda deployment
        // Uncomment when @EnableWebSocket is enabled for local development
        
        // Call/SMS notification WebSocket endpoint
        // registry.addHandler(callNotificationHandler, "/ws/calls")
        //         .setAllowedOrigins("*")
        //         .withSockJS();

        // General CareConnect WebSocket endpoint for real-time updates
        // registry.addHandler(careConnectWebSocketHandler, "/ws/careconnect")
        //         .setAllowedOrigins("*")
        //         .withSockJS();

        // Notification WebSocket endpoint (no SockJS fallback)
        // registry.addHandler(notificationWebSocketHandler, "/ws/notifications")
        //         .setAllowedOrigins("*");
    }
}
