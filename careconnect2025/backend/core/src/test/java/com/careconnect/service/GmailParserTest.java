package com.careconnect.service;

import com.careconnect.dto.GmailDigestPayload;
import com.careconnect.model.USPSDigest;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

class GmailParserTest {

    private final GmailParser parser = new GmailParser();

    @Test
    void extractsSenderAndTrackingForPackages() throws IOException {
        Path htmlPath = Path.of("src/test/resources/usps/gmail-digest-package.html");
        String html = Files.readString(htmlPath);
        GmailDigestPayload payload = new GmailDigestPayload(html, Map.of(), OffsetDateTime.now(ZoneOffset.UTC));

        USPSDigest digest = parser.toDomain(payload);
        assertNotNull(digest);
        assertEquals(1, digest.packages().size(), "should find one package");
        assertEquals("Awesome Vendor LLC", digest.packages().get(0).getSender());
        assertEquals("9400 1234 5678", digest.packages().get(0).getTrackingNumber());
    }
}
