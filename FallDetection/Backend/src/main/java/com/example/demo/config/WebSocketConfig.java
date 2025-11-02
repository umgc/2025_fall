package com.example.demo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import com.example.demo.websocket.SkeletonWebSocketHandler;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    
    private final SkeletonWebSocketHandler skeletonWebSocketHandler;
    
    public WebSocketConfig(SkeletonWebSocketHandler skeletonWebSocketHandler) {
        this.skeletonWebSocketHandler = skeletonWebSocketHandler;
    }
    
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(skeletonWebSocketHandler, "/ws/skeleton")
                .setAllowedOrigins("*");  // Allow all origins for development
    }
}
