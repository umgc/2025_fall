package com.careconnect.controller;

import com.careconnect.model.USPSDigest;
import com.careconnect.service.USPSDigestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/usps")
@RequiredArgsConstructor
public class UspsDigestController {

    private final USPSDigestService uspsDigestService;

    @GetMapping("/latest")
    public ResponseEntity<USPSDigest> getLatestDigest(
            @RequestParam(defaultValue = "demo-user") String userId) {

        return uspsDigestService.latestForUser(userId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping("/clear-cache")
    public ResponseEntity<String> clearCache(
            @RequestParam(defaultValue = "demo-user") String userId) {

        uspsDigestService.clearCacheForUser(userId);
        return ResponseEntity.ok("Cache cleared successfully for user: " + userId);
    }
}
