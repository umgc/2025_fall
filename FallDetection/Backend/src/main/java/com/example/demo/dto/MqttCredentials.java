package com.example.demo.dto;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class MqttCredentials {
    private String username;
    private String passcode;
    
    @JsonProperty("wss_url")
    private String wssUrl;
    
    @JsonProperty("expires_at")
    private Long expiresAt;
    
    @JsonProperty("expires_in")
    private Integer expiresIn;
}