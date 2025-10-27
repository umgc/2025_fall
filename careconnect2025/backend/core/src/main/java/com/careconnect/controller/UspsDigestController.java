package com.careconnect.controller;

import com.careconnect.service.USPSDigestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.careconnect.model.USPSDigest;
import org.springframework.format.annotation.DateTimeFormat;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/usps")
@RequiredArgsConstructor
public class UspsDigestController {

    private final USPSDigestService uspsDigestService;

    @GetMapping("/latest")
    public ResponseEntity<USPSDigest> getLatestDigest(
            @RequestParam(defaultValue = "demo-user") String userId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {

        var digest = date != null
                ? uspsDigestService.digestForDate(userId, date)
                : uspsDigestService.latestForUser(userId);

        return digest
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
