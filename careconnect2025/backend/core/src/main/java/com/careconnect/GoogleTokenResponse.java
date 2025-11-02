package com.careconnect.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.Instant;

public record GoogleTokenResponse(
        @JsonProperty("access_token") String accessToken,
        @JsonProperty("refresh_token") String refreshToken,
        @JsonProperty("expires_in") Long expiresIn,
        @JsonProperty("scope") String scope,
        @JsonProperty("token_type") String tokenType
) {
    public Instant computeExpiryFromNow() {
        return Instant.now().plusSeconds(expiresIn != null ? expiresIn : 3600);
    }
}
