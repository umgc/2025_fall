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
    public ResponseEntity<UspsDigest> getDigest(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String userId) {

        // Try to get userId from JWT first, then from parameter, then fallback
        String actualUserId;
        if (jwt != null && jwt.getSubject() != null) {
            actualUserId = jwt.getSubject();
        } else if (userId != null && !userId.isEmpty()) {
            actualUserId = userId;
        } else {
            actualUserId = "demo-user"; // fallback for testing
        }

        System.out.println("[USPS] Fetching digest for userId: " + actualUserId);

        var digest = service.latestForUser(actualUserId)
                .orElseGet(() -> {
                    System.out.println("[USPS] No digest found, returning empty");
                    return new UspsDigest(null, java.util.List.of(), java.util.List.of());
                });

        // Ensure non-null lists before logging
        int mailCount = digest.getMailPieces() != null ? digest.getMailPieces().size() : 0;
        int packageCount = digest.getPackages() != null ? digest.getPackages().size() : 0;

        System.out.println("[USPS] Returning digest with " + mailCount + " mail pieces and " + packageCount + " packages");

        return ResponseEntity.ok(digest);
    }

    @PostMapping("/clear-cache")
    public ResponseEntity<String> clearCache(@RequestParam(required = false) String userId) {
        String actualUserId = userId != null ? userId : "demo-user";

        // This will force a fresh fetch by clearing cache
        System.out.println("[USPS] Clearing cache for userId: " + actualUserId);
        service.clearCache(actualUserId);

        return ResponseEntity.ok("Cache cleared for user " + actualUserId);
    }
}
