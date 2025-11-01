package com.example.demo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class PreviewToken {
    @JsonProperty("preview_token")
    private Long previewToken;
    
    @JsonProperty("expires_at")
    private Long expiresAt;
    
    @JsonProperty("expires_in")
    private Integer expiresIn;
}
