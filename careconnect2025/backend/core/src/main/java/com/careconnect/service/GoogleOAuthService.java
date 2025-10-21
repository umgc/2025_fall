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

        if (token == null || token.accessToken() == null) {
            throw new IllegalStateException("Google token exchange failed");
        }

        var ec = new EmailCredential();
        ec.setUserId(userId);
        ec.setProvider(EmailCredential.Provider.GMAIL);
        ec.setAccessTokenEnc(tokenCryptor.encrypt(token.accessToken()));
        if (token.refreshToken() != null) {
            ec.setRefreshTokenEnc(tokenCryptor.encrypt(token.refreshToken()));
        } else {
            // keep last refresh token if this response omitted it
            credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.GMAIL)
                    .map(EmailCredential::getRefreshTokenEnc)
                    .ifPresent(ec::setRefreshTokenEnc);
        }
        Instant exp = token.computeExpiryFromNow();
        ec.setExpiresAt(exp);

        credRepo.save(ec);
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
