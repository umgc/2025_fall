package com.careconnect.service;

import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Stores temporary Alexa authorization codes mapped to JWT tokens.
 * Codes expire automatically after a short period (e.g., 120 seconds).
 */
@Service
public class AlexaCodeStoreService {

    private static final long EXPIRATION_SECONDS = 120; // ⏱️ Temp codes last 1 minute
    private final Map<String, Entry> codeStore = new ConcurrentHashMap<>();
    private final Map<String, String> refreshTokenStore = new ConcurrentHashMap<>();

    /**
     * Generate a new temporary code tied to a user's JWT.
     */
    public String generateCode(String jwtToken) {
        String code = UUID.randomUUID().toString();
        codeStore.put(code, new Entry(jwtToken, Instant.now().plusSeconds(EXPIRATION_SECONDS)));
        return code;
    }

    /**
     * Exchange a code for the associated JWT.
     * Once consumed, the code is invalidated (one-time use).
     */
    public String consumeCode(String code) {
        Entry entry = codeStore.remove(code);
        if (entry == null) {
            return null; // invalid or already used
        }
        if (Instant.now().isAfter(entry.expiration)) {
            return null; // expired
        }
        return entry.jwt;
    }

    public void saveRefreshToken(String refreshToken, String jwtToken) {
        refreshTokenStore.put(refreshToken, jwtToken);
    }

    public String findJwtByRefreshToken(String refreshToken) {
        return refreshTokenStore.get(refreshToken);
    }

    /**
     * Background cleanup (optional optimization).
     * Could be scheduled if you expect many tokens.
     */
    public void cleanupExpiredCodes() {
        Instant now = Instant.now();
        codeStore.entrySet().removeIf(e -> now.isAfter(e.getValue().expiration));
    }

    private static class Entry {
        final String jwt;
        final Instant expiration;

        Entry(String jwt, Instant expiration) {
            this.jwt = jwt;
            this.expiration = expiration;
        }
    }
}
