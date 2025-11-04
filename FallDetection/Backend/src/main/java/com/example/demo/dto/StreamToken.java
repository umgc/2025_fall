package com.example.demo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class StreamToken {
    @JsonProperty("stream_token")
    private Long streamToken;
    
    @JsonProperty("expires_at")
    private Long expiresAt;
    
    @JsonProperty("expires_in")
    private Integer expiresIn;
}