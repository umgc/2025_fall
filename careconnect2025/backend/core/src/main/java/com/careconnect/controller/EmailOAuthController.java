package com.careconnect.controller;

import com.careconnect.service.GoogleOAuthService;
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

    @Value("${google.oauth.client-id}")    String clientId;
    @Value("${google.oauth.redirect-uri}") String redirectUri;
    @Value("${google.oauth.scope}")        String scope;

    @GetMapping("/google/start")
    public ResponseEntity<Void> start(@RequestParam String userId) {
        System.out.println("[OAuth] clientId=" + clientId);
        System.out.println("[OAuth] redirectUri=" + redirectUri);
        System.out.println("[OAuth] scope=" + scope);

        String authUrl = UriComponentsBuilder
                .fromHttpUrl("https://accounts.google.com/o/oauth2/v2/auth")
                .queryParam("response_type", "code")
                .queryParam("client_id", clientId)
                .queryParam("redirect_uri", UriUtils.encode(redirectUri, StandardCharsets.UTF_8))
                .queryParam("scope", UriUtils.encode(scope, StandardCharsets.UTF_8))
                .queryParam("access_type", "offline")
                .queryParam("prompt", "consent")
                .queryParam("state", UriUtils.encode("u:" + userId, StandardCharsets.UTF_8))
                .build(true)                                     // values already encoded
                .toUriString();

        System.out.println("[OAuth] AUTH URL = " + authUrl);
        return ResponseEntity.status(302).location(URI.create(authUrl)).build();
    }

    @GetMapping("/google/callback")
    public ResponseEntity<Void> callback(@RequestParam String code, @RequestParam String state) {
        String userId = parseUserId(state);           // <-- returns String
        googleOAuthService.exchange(userId, code);    // <-- matches service signature
        return ResponseEntity.status(302).location(URI.create("/settings")).build();
    }

    private static String parseUserId(String s){
        if (s != null && s.startsWith("u:")) return s.substring(2);
        throw new IllegalArgumentException("Invalid state");
    }
}
