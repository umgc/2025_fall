package com.example.demo.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class TokenResponse {
    @JsonProperty("access_token")
    private String accessToken;
    
    @JsonProperty("token_type")
    private String tokenType;
    
    @JsonProperty("expires_in")
    private Integer expiresIn;
    
    @JsonProperty("status_code")
    private Integer statusCode;
    
    @JsonProperty("message")
    private String message;
    
    @JsonProperty("success")
    private Boolean success;
    
    @JsonProperty("state")
    private String state;
    
    @JsonProperty("data")
    private TokenData data;
    
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TokenData {
        @JsonProperty("group_id")
        private Long groupId;
        
        @JsonProperty("user_id")
        private Long userId;
        
        @JsonProperty("email")
        private String email;
        
        @JsonProperty("is_group_owner")
        private Boolean isGroupOwner;
    }
}