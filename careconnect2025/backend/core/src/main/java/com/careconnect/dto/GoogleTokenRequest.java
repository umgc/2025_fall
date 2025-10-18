package com.careconnect.dto;

import lombok.Data;

@Data
public class GoogleTokenRequest {
    private String code;
    private String redirectUri;
}
