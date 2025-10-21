package com.careconnect.service;

import com.careconnect.model.EmailCredential;
import com.careconnect.repository.EmailCredentialRepository;
import com.careconnect.dto.GoogleTokenResponse;
import com.careconnect.security.TokenCryptor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class GoogleOAuthService {

    private final WebClient http;
    private final EmailCredentialRepository credRepo;
    private final TokenCryptor tokenCryptor;

    @Value("${google.oauth.client-id}")    String clientId;
    @Value("${google.oauth.client-secret}")String clientSecret;
    @Value("${google.oauth.redirect-uri}") String redirectUri;

    public void exchange(String userId, String code) {
        try {
            System.out.println("[GoogleOAuth] Starting token exchange for userId: " + userId);
            System.out.println("[GoogleOAuth] Using clientId: " + (clientId != null ? clientId.substring(0, Math.min(12, clientId.length())) + "..." : "null"));
            System.out.println("[GoogleOAuth] Using redirectUri: " + redirectUri);

            GoogleTokenResponse token = http.post()
                    .uri("https://oauth2.googleapis.com/token")
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(BodyInserters.fromFormData("code", code)
                            .with("client_id", clientId)
                            .with("client_secret", clientSecret)
                            .with("redirect_uri", redirectUri)
                            .with("grant_type", "authorization_code"))
                    .retrieve()
                    .bodyToMono(GoogleTokenResponse.class)
                    .block();

            System.out.println("[GoogleOAuth] Token response received: " + (token != null ? "yes" : "null"));

            if (token == null || token.accessToken() == null) {
                throw new IllegalStateException("Google token exchange failed - no access token received");
            }

            System.out.println("[GoogleOAuth] Access token received, creating EmailCredential");

            var ec = new EmailCredential();
            ec.setUserId(userId);
            ec.setProvider(EmailCredential.Provider.GMAIL);
            ec.setAccessTokenEnc(tokenCryptor.encrypt(token.accessToken()));

            if (token.refreshToken() != null) {
                System.out.println("[GoogleOAuth] Refresh token present, encrypting");
                ec.setRefreshTokenEnc(tokenCryptor.encrypt(token.refreshToken()));
            } else {
                System.out.println("[GoogleOAuth] No refresh token, checking for existing one");
                // keep last refresh token if this response omitted it
                credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.GMAIL)
                        .map(EmailCredential::getRefreshTokenEnc)
                        .ifPresent(ec::setRefreshTokenEnc);
            }

            Instant exp = token.computeExpiryFromNow();
            ec.setExpiresAt(exp);
            System.out.println("[GoogleOAuth] Token expires at: " + exp);

            System.out.println("[GoogleOAuth] Saving EmailCredential to database");
            credRepo.save(ec);
            System.out.println("[GoogleOAuth] Token exchange completed successfully");

        } catch (Exception e) {
            System.err.println("[GoogleOAuth] Token exchange failed: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("Google OAuth token exchange failed: " + e.getMessage(), e);
        }
    }

    // refresh utility
    public EmailCredential ensureFreshToken(EmailCredential current) {
        if (current.getExpiresAt() != null &&
                current.getExpiresAt().isAfter(Instant.now().plusSeconds(120))) {
            return current; // still fresh
        }
        String refresh = tokenCryptor.decrypt(current.getRefreshTokenEnc());
        if (refresh == null || refresh.isBlank()) return current;

        GoogleTokenResponse token = http.post()
                .uri("https://oauth2.googleapis.com/token")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(BodyInserters.fromFormData("refresh_token", refresh)
                        .with("client_id", clientId)
                        .with("client_secret", clientSecret)
                        .with("grant_type", "refresh_token"))
                .retrieve()
                .bodyToMono(GoogleTokenResponse.class)
                .block();

        if (token != null && token.accessToken() != null) {
            current.setAccessTokenEnc(tokenCryptor.encrypt(token.accessToken()));
            current.setExpiresAt(token.computeExpiryFromNow());
            credRepo.save(current);
        }
        return current;
    }
}
