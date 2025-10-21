package com.careconnect.controller;

import com.careconnect.service.GoogleOAuthService;
import com.careconnect.repository.EmailCredentialRepository;
import com.careconnect.model.EmailCredential;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.web.util.UriUtils;

import java.net.URI;
import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/oauth")
@RequiredArgsConstructor
public class EmailOAuthController {

    private final GoogleOAuthService googleOAuthService;
    private final EmailCredentialRepository credRepo;

    @Value("${google.oauth.client-id}")    String clientId;
    @Value("${google.oauth.redirect-uri}") String redirectUri;
    @Value("${google.oauth.scope}")        String scope;
    @Value("${google.oauth.frontend-url}") String frontendBaseUrl;

    @GetMapping("/google/start")
    public ResponseEntity<Void> start(@RequestParam String userId, @RequestParam(required = false) String returnUrl) {
        System.out.println("[OAuth] clientId=" + clientId);
        System.out.println("[OAuth] redirectUri=" + redirectUri);
        System.out.println("[OAuth] scope=" + scope);
        System.out.println("[OAuth] returnUrl=" + returnUrl);

        // Encode state with both userId and returnUrl
        String stateData = "u:" + userId;
        if (returnUrl != null && !returnUrl.isEmpty()) {
            stateData += "|r:" + returnUrl;
        }

        String authUrl = UriComponentsBuilder
                .fromHttpUrl("https://accounts.google.com/o/oauth2/v2/auth")
                .queryParam("response_type", "code")
                .queryParam("client_id", clientId)
                .queryParam("redirect_uri", UriUtils.encode(redirectUri, StandardCharsets.UTF_8))
                .queryParam("scope", UriUtils.encode(scope, StandardCharsets.UTF_8))
                .queryParam("access_type", "offline")
                .queryParam("prompt", "consent")
                .queryParam("state", UriUtils.encode(stateData, StandardCharsets.UTF_8))
                .build(true)                                     // values already encoded
                .toUriString();

        System.out.println("[OAuth] AUTH URL = " + authUrl);
        return ResponseEntity.status(302).location(URI.create(authUrl)).build();
    }

    @GetMapping("/google/callback")
    public ResponseEntity<Void> callback(@RequestParam String code, @RequestParam String state) {
        try {
            System.out.println("[OAuth] Callback received - code: " + (code != null ? "present" : "null"));
            System.out.println("[OAuth] Callback received - state: " + state);

            String[] stateData = parseStateData(state);
            String userId = stateData[0];
            String returnUrl = stateData[1];
            System.out.println("[OAuth] Parsed userId: " + userId);
            System.out.println("[OAuth] Parsed returnUrl: " + returnUrl);

            googleOAuthService.exchange(userId, code);
            System.out.println("[OAuth] Token exchange successful");

            // Use returnUrl if provided, otherwise fallback to default
            String frontendUrl;
            if (returnUrl != null && !returnUrl.isEmpty()) {
                frontendUrl = returnUrl;
                System.out.println("[OAuth] Using dynamic returnUrl: " + frontendUrl);
            } else {
                frontendUrl = frontendBaseUrl + "/usps-test";
                System.out.println("[OAuth] Using fallback URL: " + frontendUrl);
            }

            System.out.println("[OAuth] Final redirect URL: " + frontendUrl);

            // Validate URL format
            try {
                new java.net.URL(frontendUrl);
                System.out.println("[OAuth] URL validation successful");
            } catch (java.net.MalformedURLException e) {
                System.err.println("[OAuth] Invalid URL format: " + frontendUrl);
                frontendUrl = frontendBaseUrl + "/usps-test";
                System.out.println("[OAuth] Using fallback after URL validation failure: " + frontendUrl);
            }

            return ResponseEntity.status(302).location(URI.create(frontendUrl)).build();
        } catch (Exception e) {
            System.err.println("[OAuth] Callback error: " + e.getMessage());
            e.printStackTrace();

            // Redirect to settings with error parameter
            String errorUrl = "/settings?error=" + java.net.URLEncoder.encode(e.getMessage(), java.nio.charset.StandardCharsets.UTF_8);
            return ResponseEntity.status(302).location(URI.create(errorUrl)).build();
        }
    }


    private static String[] parseStateData(String state) {
        if (state == null) throw new IllegalArgumentException("Invalid state: null");

        String userId = null;
        String returnUrl = null;

        String[] parts = state.split("\\|");
        for (String part : parts) {
            if (part.startsWith("u:")) {
                userId = part.substring(2);
            } else if (part.startsWith("r:")) {
                returnUrl = part.substring(2);
            }
        }

        if (userId == null) {
            throw new IllegalArgumentException("Invalid state: missing userId");
        }

        return new String[]{userId, returnUrl};
    }
}
