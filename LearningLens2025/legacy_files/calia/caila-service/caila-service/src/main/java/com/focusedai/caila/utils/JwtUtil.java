package com.focusedai.caila.utils;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;
import java.util.Date;
import java.util.function.Function;

@Component
public class JwtUtil {
    
    // ✅ CORRECTED: Changed from ${JWT_SECRET} to ${jwt.secret}
    @Value("${jwt.secret}")
    private String jwtSecret;
    
    // ✅ CORRECTED: Changed from ${ENCRYPTION_KEY} to ${encryption.key}
    @Value("${encryption.key}")
    private String encryptionKey;

    private javax.crypto.SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(this.jwtSecret.getBytes());
    }

    // --- Decryption ---
    private String decrypt(String encryptedData) {
        if (encryptedData == null) return null;
        try {
            Cipher cipher = Cipher.getInstance("AES");
            SecretKeySpec keySpec = new SecretKeySpec(encryptionKey.getBytes(), "AES");
            cipher.init(Cipher.DECRYPT_MODE, keySpec);
            return new String(cipher.doFinal(Base64.getDecoder().decode(encryptedData)));
        } catch (Exception e) {
            throw new RuntimeException("Decryption failed", e);
        }
    }

    // --- Token Validation & Extraction ---
    public Boolean validateToken(String token) {
        try {
            Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public Claims extractAllClaims(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    public String extractUserId(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public String extractLMS(String token) {
        return extractClaim(token, claims -> claims.get("lms", String.class));
    }

    public String extractUserIdentifier(String token) {
        String encryptedIdentifier = extractClaim(token, claims -> claims.get("identifier", String.class));
        return decrypt(encryptedIdentifier);
    }

    public String extractUserRole(String token) {
        return extractClaim(token, claims -> claims.get("role", String.class));
    }

    public Boolean isTokenExpired(String token) {
        return extractClaim(token, Claims::getExpiration).before(new Date());
    }

    // --- Google Session Data Extraction ---
    public String extractGoogleAccessToken(String token) {
        String encryptedToken = extractClaim(token, claims -> claims.get("googleAccessToken", String.class));
        return decrypt(encryptedToken);
    }

    public String extractGoogleRefreshToken(String token) {
        String encryptedToken = extractClaim(token, claims -> claims.get("googleRefreshToken", String.class));
        return decrypt(encryptedToken);
    }

    public Long extractGoogleTokenExpiry(String token) {
        return extractClaim(token, claims -> claims.get("googleTokenExpiry", Long.class));
    }

    public boolean isGoogleTokenExpired(String token) {
        Long expiry = extractGoogleTokenExpiry(token);
        return expiry != null && System.currentTimeMillis() > expiry;
    }

    // --- Moodle Session Data Extraction ---
    public String extractMoodleDomain(String token) {
        String encryptedDomain = extractClaim(token, claims -> claims.get("moodleDomain", String.class));
        return decrypt(encryptedDomain);
    }

    public String extractwebServiceToken(String token) {
        String encryptedWebServiceToken = extractClaim(token, claims -> claims.get("webServiceToken", String.class));
        return decrypt(encryptedWebServiceToken);
    }

    // --- User Type Check ---
    public boolean isGoogleUser(String token) {
        return "googleClassroom".equals(extractLMS(token));
    }

    public boolean isMoodleUser(String token) {
        return "moodle".equals(extractLMS(token));
    }
}