package com.careconnect.service;

import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;

@Service
public class OutlookClient {
    public record OutlookRaw(String html, Map<String, String> cidDataUrls, Instant received) {}

    public Optional<OutlookRaw> fetchLatestDigest(String accessToken) {
        // TODO: implement real Graph calls; returning empty for now.
        return Optional.empty();
    }
}
