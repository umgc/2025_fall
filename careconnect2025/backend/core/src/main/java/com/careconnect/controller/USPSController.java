package com.careconnect.controller;

import com.careconnect.model.USPSDigest;
import com.careconnect.service.USPSDigestService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/v1/api/usps")
@RequiredArgsConstructor
public class USPSController {

    private final USPSDigestService service;

    @GetMapping("/mail")
    public ResponseEntity<USPSDigest> getDigest(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        var userId = jwt != null ? jwt.getSubject() : "demo-user"; // fallback for early testing
        var digestOpt = date != null
                ? service.digestForDate(userId, date)
                : service.latestForUser(userId);
        var digest = digestOpt.orElseGet(() -> new USPSDigest(null, java.util.List.of(), java.util.List.of()));
        return ResponseEntity.ok(digest);
    }
}
