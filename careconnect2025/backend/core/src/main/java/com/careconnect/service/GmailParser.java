package com.careconnect.service;

import com.careconnect.model.ActionLinks;
import com.careconnect.model.MailPiece;
import com.careconnect.model.PackageItem;
import com.careconnect.model.UspsDigest;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.springframework.stereotype.Component;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Turns a Gmail USPS digest HTML payload into your domain model.
 * This is a compiling skeleton — fill in real parsing later.
 */
@Component
public class GmailParser {

    // ---------- PUBLIC API ----------
    public UspsDigest toDomain(String rawHtml) {
        // parse HTML (safe even if rawHtml is null)
        Document doc = Jsoup.parse(rawHtml == null ? "" : rawHtml);

        // Try to extract dates (as strings), then convert to OffsetDateTime
        OffsetDateTime digestDate   = parseToOdt(extractDigestDate(doc));
        OffsetDateTime expectedDate = parseToOdt(extractExpectedDate(doc));
        if (digestDate == null) digestDate = OffsetDateTime.now(ZoneOffset.UTC);

// MailPiece now gets OffsetDateTime, not String
        MailPiece mp = new MailPiece(
                "mp-1",
                "USPS Informed Delivery",
                "Daily Digest",
                "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAnIGhlaWdodD0nMjAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHJlY3Qgd2lkdGg9JzQwJyBoZWlnaHQ9JzIwJyBmaWxsPSIjZGRkIi8+PC9zdmc+",
                digestDate,                            // <-- was digestDate.toString()
                ActionLinks.defaults(null)
        );

        List<PackageItem> packages;
        if (expectedDate != null) {
            String tracking = "9400100000000000000000";
            packages = List.of(new PackageItem(
                    tracking,
                    expectedDate,                       // <-- was expectedDate.toString()
                    ActionLinks.defaults("https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=" + tracking)
            ));
        } else {
            packages = List.of();
        }

        return new UspsDigest(digestDate, List.of(mp), packages);
    }

    // ---------- HELPERS ----------
    private static final DateTimeFormatter RFC1123 = DateTimeFormatter.RFC_1123_DATE_TIME;

    /** Try ISO-8601 first, then RFC 1123; return null if unparseable. */
    private static OffsetDateTime parseToOdt(String s) {
        if (s == null || s.isBlank()) return null;
        try {
            return OffsetDateTime.parse(s); // ISO 8601
        } catch (DateTimeParseException ignore) {
            try {
                return ZonedDateTime.parse(s, RFC1123).toOffsetDateTime(); // email Date: header
            } catch (DateTimeParseException ignore2) {
                try {
                    // last-ditch: naive local datetime -> system zone -> offset
                    return LocalDateTime.parse(s).atZone(ZoneId.systemDefault()).toOffsetDateTime();
                } catch (DateTimeParseException ignore3) {
                    return null;
                }
            }
        }
    }

    // Placeholder extractors — return Strings that parseToOdt(...) can handle.
    // Replace with Jsoup selectors once you inspect a real Gmail HTML.
    private String extractDigestDate(Document doc) {
        // e.g., look for <time datetime="..."> or a header with a date
        return null;
    }

    private String extractExpectedDate(Document doc) {
        // e.g., look for text like "Expected Delivery: 2025-10-17T12:00:00-05:00"
        return null;
    }
}
