package com.careconnect.service;

import com.careconnect.dto.GmailDigestPayload;
import com.careconnect.model.UspsDigest;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.OffsetDateTime;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class GmailParserTest {

    private final GmailParser parser = new GmailParser();

    @Test
    void parsesSampleDigestHtml() throws Exception {
        String html = Files.readString(Path.of("src/test/resources/usps/gmail_digest_sample.html"));
        String img1 = "data:image/png;base64," + java.util.Base64.getEncoder()
                .encodeToString("piece1".getBytes(StandardCharsets.UTF_8));
        String img2 = "data:image/png;base64," + java.util.Base64.getEncoder()
                .encodeToString("piece2".getBytes(StandardCharsets.UTF_8));

        GmailDigestPayload payload = new GmailDigestPayload(
                html,
                Map.of("mailpiece_1", img1, "mailpiece_2", img2),
                OffsetDateTime.parse("2025-02-14T13:30:00Z")
        );

        UspsDigest digest = parser.toDomain(payload);

        assertNotNull(digest);
        assertEquals("2025-02-14", digest.getDigestDate().toLocalDate().toString());

        assertEquals(1, digest.getPackages().size());
        assertEquals("9400100252801234567890", digest.getPackages().get(0).getTrackingNumber());
        assertTrue(digest.getPackages().get(0).getActionLinks().getTrack().contains("9400100252801234567890"));

        assertEquals(2, digest.getMailPieces().size());
        assertEquals("ACME Bank", digest.getMailPieces().get(0).getSender());
        assertEquals("Your monthly statement is ready.", digest.getMailPieces().get(0).getSubject());
        assertEquals(img1, digest.getMailPieces().get(0).getThumbnailUrl());
    }
}
