package com.careconnect.controller;

import com.careconnect.model.UspsDigest;
import com.careconnect.service.UspsDigestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/usps")
@RequiredArgsConstructor
public class UspsController {

    private final UspsDigestService service;

    @GetMapping("/digest")
    public ResponseEntity<UspsDigest> getDigest(@AuthenticationPrincipal Jwt jwt) {
        var userId = jwt != null ? jwt.getSubject() : "demo-user"; // fallback for early testing
        var digest = service.latestForUser(userId).orElseGet(() -> new UspsDigest(null, java.util.List.of(), java.util.List.of()));
        return ResponseEntity.ok(digest);
    }
}
