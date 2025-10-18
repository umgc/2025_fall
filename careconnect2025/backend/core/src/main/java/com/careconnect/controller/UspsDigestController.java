package com.careconnect.controller;

import com.careconnect.model.UspsDigest;
import com.careconnect.service.UspsDigestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/usps")
@RequiredArgsConstructor
public class UspsDigestController {

    private final UspsDigestService uspsDigestService;

    @GetMapping("/latest")
    public ResponseEntity<UspsDigest> getLatestDigest(
            @RequestParam(defaultValue = "demo-user") String userId) {

        return uspsDigestService.latestForUser(userId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }
}
