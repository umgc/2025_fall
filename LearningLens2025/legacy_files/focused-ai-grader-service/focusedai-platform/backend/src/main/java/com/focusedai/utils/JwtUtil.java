package com.focusedai.utils;

import java.util.Base64;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import java.util.function.Function;
import io.jsonwebtoken.security.Keys;

@Component
public class JwtUtil {
    
    @Value("${jwt.secret}")
    private String jwtSecret;
    
    @Value("${encryption.key}")
    private String encryptionKey; // Must be 32 characters for AES-256

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(this.jwtSecret.getBytes());
    }

    // --- Encryption/Decryption ---
    private String encrypt(String data) {
        if (data == null) return null;
        try {
            Cipher cipher = Cipher.getInstance("AES");
            SecretKeySpec keySpec = new SecretKeySpec(encryptionKey.getBytes(), "AES");
            cipher.init(Cipher.ENCRYPT_MODE, keySpec);
            return Base64.getEncoder().encodeToString(cipher.doFinal(data.getBytes()));
        } catch (Exception e) {
            throw new RuntimeException("Encryption failed", e);
        }
    }
    
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
            System.err.println("JWT Validation Error: " + e.getMessage());
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
        return decrypt(encryptedIdentifier); // Decrypt before returning
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

    public String extractWebServiceToken(String token) {
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