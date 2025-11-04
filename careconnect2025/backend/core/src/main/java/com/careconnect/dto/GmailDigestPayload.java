package com.careconnect.dto;

import java.time.OffsetDateTime;
import java.util.Map;

public record GmailDigestPayload(
        String htmlBody,
        Map<String, String> inlineCidData,
        OffsetDateTime receivedAt
) {
}
