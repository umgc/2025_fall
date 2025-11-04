package com.careconnect.controller;

import com.careconnect.model.USPSDigest;
import com.careconnect.service.USPSDigestService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

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

    @GetMapping("/search")
    public ResponseEntity<List<Map<String, Object>>> search(
            @RequestParam(defaultValue = "demo-user") String userId,
            @RequestParam String keyword) {

        var results = uspsDigestService.search(userId, keyword);
        return ResponseEntity.ok(results);
    }

    @PostMapping("/clear-cache")
    public ResponseEntity<String> clearCache(
            @RequestParam(defaultValue = "demo-user") String userId) {

        uspsDigestService.clearCacheForUser(userId);
        return ResponseEntity.ok("Cache cleared successfully for user: " + userId);
    }
}
