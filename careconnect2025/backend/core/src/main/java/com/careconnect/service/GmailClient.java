package com.careconnect.service;

import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;

@Service
public class GmailClient {
    public record GmailRaw(String html, Map<String, byte[]> cidMap, Instant internalDate) {}

    public Optional<GmailRaw> fetchLatestDigest(String accessToken) {
        // TODO: implement real Gmail calls; returning empty keeps wiring simple for now.
        return Optional.empty();
    }
}
