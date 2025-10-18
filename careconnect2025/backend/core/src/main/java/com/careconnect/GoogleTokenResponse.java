package com.careconnect.dto;

import java.time.Instant;

public record GoogleTokenResponse(
        String accessToken,
        String refreshToken,
        Long expiresIn,
        String scope,
        String tokenType
) {
    public Instant computeExpiryFromNow() {
        return Instant.now().plusSeconds(expiresIn != null ? expiresIn : 3600);
    }
}
