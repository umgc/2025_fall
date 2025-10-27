package com.careconnect.service;

import com.careconnect.dto.GmailDigestPayload;
import com.careconnect.model.ActionLinks;
import com.careconnect.model.MailPiece;
import com.careconnect.model.PackageItem;
import com.careconnect.model.UspsDigest;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.springframework.stereotype.Component;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
public class GmailParser {

    private static final Pattern TRACKING_PATTERN = Pattern.compile("(\\d{10,})");
    private static final Pattern FROM_PATTERN = Pattern.compile("from\\s+(.+)", Pattern.CASE_INSENSITIVE);
    private static final Pattern EXPECTED_PATTERN = Pattern.compile("Expected Delivery(?: Day)?:\\s*(.+)", Pattern.CASE_INSENSITIVE);
    private static final Pattern DIGEST_HEADING_PATTERN = Pattern.compile("(?i)Daily Digest(?: for)?\\s*(.*)");
    private static final DateTimeFormatter RFC1123 = DateTimeFormatter.RFC_1123_DATE_TIME;
    private static final DateTimeFormatter[] LOCAL_DATE_FORMATS = new DateTimeFormatter[]{
            DateTimeFormatter.ofPattern("EEEE, MMMM d, yyyy", Locale.US),
            DateTimeFormatter.ofPattern("MMMM d, yyyy", Locale.US),
            DateTimeFormatter.ofPattern("M/d/yyyy", Locale.US)
    };

    public UspsDigest toDomain(GmailDigestPayload payload) {
        if (payload == null) return null;

        String htmlBody = payload.htmlBody() == null ? "" : payload.htmlBody();
        System.out.println("[GmailParser] Processing HTML body length: " + htmlBody.length());

        Document doc = Jsoup.parse(htmlBody);
        inlineCidImages(doc, payload.inlineCidData());

        OffsetDateTime digestDate = resolveDigestDate(doc, payload.receivedAt());
        List<PackageItem> packages = extractPackages(doc, digestDate);
        List<MailPiece> mailPieces = extractMailPieces(doc, payload, digestDate);

        System.out.println("[GmailParser] Extracted " + packages.size() + " packages and " + mailPieces.size() + " mail pieces");

        return new UspsDigest(digestDate, mailPieces, packages);
    }

    private void inlineCidImages(Document doc, Map<String, String> cidMap) {
        if (cidMap == null || cidMap.isEmpty()) return;
        Map<String, String> lookup = cidMap.entrySet().stream()
                .collect(Collectors.toMap(
                        e -> normalizeCid(e.getKey()),
                        Map.Entry::getValue,
                        (a, b) -> a));

        for (Element img : doc.select("img[src^=cid:]")) {
            String cid = normalizeCid(img.attr("src").substring(img.attr("src").indexOf(':') + 1));
            String dataUrl = lookup.get(cid);
            if (dataUrl != null) {
                img.attr("src", dataUrl);
            }
        }
    }

    private String normalizeCid(String raw) {
        return raw == null ? "" : raw.replace("<", "").replace(">", "").trim().toLowerCase(Locale.ROOT);
    }

    private OffsetDateTime resolveDigestDate(Document doc, OffsetDateTime fallback) {
        String candidate = null;
        Element time = doc.selectFirst("time[datetime]");
        if (time != null) {
            candidate = firstNonBlank(time.attr("datetime"), time.text());
        }
        if (isBlank(candidate)) {
            Element metaDate = doc.selectFirst("meta[name=date]");
            if (metaDate != null) {
                candidate = metaDate.attr("content");
            }
        }
        if (isBlank(candidate)) {
            Element heading = doc.selectFirst(":matchesOwn((?i)Daily Digest)");
            if (heading != null) {
                Matcher matcher = DIGEST_HEADING_PATTERN.matcher(heading.text());
                if (matcher.find()) {
                    candidate = matcher.group(1).trim();
                }
            }
        }
        OffsetDateTime parsed = parseToOffset(candidate);
        if (parsed != null) return parsed;
        if (fallback != null) return fallback;
        return OffsetDateTime.now(ZoneOffset.UTC);
    }

    private List<PackageItem> extractPackages(Document doc, OffsetDateTime digestDate) {
        List<PackageItem> items = new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();

        System.out.println("[GmailParser] Looking for packages with selectors: .package, [data-package], article:has(.tracking-number)");
        var packageElements = doc.select(".package, [data-package], article:has(.tracking-number)");
        System.out.println("[GmailParser] Found " + packageElements.size() + " potential package elements");
        for (Element pkg : packageElements) {
            String tracking = firstNonBlank(
                    textOrNull(pkg.selectFirst(".tracking-number")),
                    extractTrackingNumber(pkg.text()));
            if (isBlank(tracking) || !seen.add(tracking)) continue;

            OffsetDateTime expected = parseToOffset(extractExpectedText(pkg));
            if (expected == null) expected = digestDate;
            String trackUrl = findTrackUrl(pkg);

            items.add(PackageItem.builder()
                    .trackingNumber(tracking)
                    .expectedDeliveryDate(expected)
                    .actionLinks(ActionLinks.defaults(trackUrl))
                    .build());
        }

        if (!items.isEmpty()) return items;

        System.out.println("[GmailParser] No packages found with structured selectors, trying text search for 'Tracking Number'");
        var trackingElements = doc.select("*:matchesOwn((?i)Tracking Number)");
        System.out.println("[GmailParser] Found " + trackingElements.size() + " elements containing 'Tracking Number'");

        for (Element element : trackingElements) {
            Matcher matcher = TRACKING_PATTERN.matcher(element.text());
            if (!matcher.find()) continue;
            String tracking = matcher.group(1);
            if (!seen.add(tracking)) continue;

            Element context = element.parent() != null ? element.parent() : element;
            OffsetDateTime expected = parseToOffset(extractExpectedText(context));
            if (expected == null) expected = digestDate;
            String trackUrl = findTrackUrl(context);

            items.add(PackageItem.builder()
                    .trackingNumber(tracking)
                    .expectedDeliveryDate(expected)
                    .actionLinks(ActionLinks.defaults(trackUrl))
                    .build());
        }

        // If still no packages found, look for summary text indicating packages exist
        if (items.isEmpty()) {
            System.out.println("[GmailParser] No detailed packages found, looking for package summary indicators");

            // Look for text like "Expected Today X item(s)" or similar patterns
            var summaryElements = doc.select("*:matchesOwn((?i)Expected.*\\d+.*item)");
            System.out.println("[GmailParser] Found " + summaryElements.size() + " summary elements with 'Expected...item'");

            // Also try broader search for elements containing "Expected" and numbers
            if (summaryElements.isEmpty()) {
                summaryElements = doc.select("*:containsOwn(Expected):matchesOwn(\\d+)");
                System.out.println("[GmailParser] Found " + summaryElements.size() + " elements containing 'Expected' and numbers");
            }

            // Debug: let's see what elements contain "Expected" at all
            if (summaryElements.isEmpty()) {
                var expectedElements = doc.select("*:containsOwn(Expected)");
                System.out.println("[GmailParser] Debug: Found " + expectedElements.size() + " elements containing 'Expected'");
                for (Element elem : expectedElements) {
                    if (elem.ownText().toLowerCase().contains("expected")) {
                        System.out.println("[GmailParser] Expected element: " + elem.tagName() + " with text: " + elem.ownText());
                    }
                }
            }

            for (Element summary : summaryElements) {
                String text = summary.text();
                System.out.println("[GmailParser] Processing summary text: " + text);

                // Extract count from text like "Expected Today 1 item(s)"
                java.util.regex.Pattern countPattern = java.util.regex.Pattern.compile("(\\d+)\\s*item");
                java.util.regex.Matcher countMatcher = countPattern.matcher(text);

                if (countMatcher.find()) {
                    int count = Integer.parseInt(countMatcher.group(1));
                    if (count > 0) {
                        System.out.println("[GmailParser] Found " + count + " packages indicated in summary");

                        // Create generic package entries
                        for (int i = 1; i <= count && i <= 5; i++) { // Limit to 5 to be safe
                            items.add(PackageItem.builder()
                                .trackingNumber("USPS-SUMMARY-" + i + "-" + System.currentTimeMillis())
                                .expectedDeliveryDate(digestDate)
                                .actionLinks(ActionLinks.defaults("https://informeddelivery.usps.com/box/dashboard"))
                                .build());
                        }
                        break; // Only process first matching summary
                    }
                }
            }
        }

        return items;
    }

    private String extractExpectedText(Element element) {
        if (element == null) return null;
        Element node = element.selectFirst("*:matchesOwn((?i)Expected Delivery)");
        if (node != null) {
            return node.text().replaceFirst("(?i).*Expected Delivery(?: Day)?[:\\s]*", "").trim();
        }
        Matcher matcher = EXPECTED_PATTERN.matcher(element.text());
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        return null;
    }

    private String findTrackUrl(Element element) {
        if (element == null) return null;
        Element link = element.selectFirst("a[href*=\"TrackConfirmAction\"]");
        return link != null ? link.attr("href") : null;
    }

    private List<MailPiece> extractMailPieces(Document doc, GmailDigestPayload payload, OffsetDateTime defaultDate) {
        List<MailPiece> pieces = new ArrayList<>();
        int counter = 1;

        System.out.println("[GmailParser] Looking for mail pieces with selectors: #mailpieces .mailpiece, [data-mailpiece-id], .mailpiece");
        var mailElements = doc.select("#mailpieces .mailpiece, [data-mailpiece-id], .mailpiece");
        System.out.println("[GmailParser] Found " + mailElements.size() + " potential mail piece elements");

        for (Element block : mailElements) {
            MailPiece piece = toMailPiece(block, payload, defaultDate, counter++);
            if (piece != null) {
                pieces.add(piece);
            }
        }

        if (pieces.isEmpty()) {
            System.out.println("[GmailParser] No structured mail pieces found, looking for fallback images");
            var imgElements = doc.select("#mailpieces img[src^=data:], #mailpieces img[src^=https], img[alt*=mailpiece]");
            System.out.println("[GmailParser] Found " + imgElements.size() + " potential mail piece images");

            // Look for any CID images that might be mail pieces
            var cidImages = doc.select("img[src^=cid:]");
            System.out.println("[GmailParser] Found " + cidImages.size() + " CID images");

            // Try to convert any CID images into mail pieces
            int cidIdx = 1;
            for (Element img : cidImages) {
                MailPiece piece = toMailPieceFromImg(img, payload, defaultDate, cidIdx++);
                if (piece != null) {
                    pieces.add(piece);
                }
            }

            // Still no images found, look for mail summary text
            if (pieces.isEmpty()) {
                System.out.println("[GmailParser] No mail piece images found, looking for mail summary indicators");

                // Look for elements that might indicate mail count
                var mailSummaryElements = doc.select("*:matchesOwn((?i)mail.*\\d+)");
                System.out.println("[GmailParser] Found " + mailSummaryElements.size() + " mail summary elements");

                // Also look for elements containing numbers that might be mail counts
                var numberElements = doc.select("*:matchesOwn(\\d+)");
                System.out.println("[GmailParser] Found " + numberElements.size() + " elements with numbers");

                // Look for simple numeric mail counts (like standalone "3" or "5")
                for (Element element : numberElements) {
                    String text = element.text().trim();

                    // Skip if it's clearly not a mail count
                    if (text.length() > 3 || text.contains(" ") ||
                        element.text().toLowerCase().contains("package") ||
                        element.text().toLowerCase().contains("tracking")) {
                        continue;
                    }

                    try {
                        int count = Integer.parseInt(text);
                        if (count > 0 && count <= 10) { // Reasonable range for daily mail
                            System.out.println("[GmailParser] Found potential mail count: " + count);

                            // Create generic mail entries
                            for (int i = 1; i <= count; i++) {
                                pieces.add(new MailPiece(
                                    "mail-summary-" + i,
                                    "USPS Informed Delivery",
                                    "Mail piece " + i,
                                    "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAnIGhlaWdodD0nMjAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHJlY3Qgd2lkdGg9JzQwJyBoZWlnaHQ9JzIwJyBmaWxsPSIjZGRkIi8+PHRleHQgeD0nMjAnIHk9JzE1JyB0ZXh0LWFuY2hvcj0nbWlkZGxlJyBmb250LWZhbWlseT0nQXJpYWwnIGZvbnQtc2l6ZT0nMTInIGZpbGw9JyM2NjYnPk1haWw8L3RleHQ+PC9zdmc+",
                                    defaultDate,
                                    ActionLinks.defaults("https://informeddelivery.usps.com/box/dashboard")
                                ));
                            }
                            break; // Only process first reasonable count found
                        }
                    } catch (NumberFormatException ignored) {
                        // Not a number, skip
                    }
                }
            }

            int idx = 1;
            for (Element img : imgElements) {
                MailPiece piece = toMailPieceFromImg(img, payload, defaultDate, idx++);
                if (piece != null) {
                    pieces.add(piece);
                }
            }
        }
        return pieces;
    }

    private MailPiece toMailPiece(Element block, GmailDigestPayload payload, OffsetDateTime defaultDate, int counter) {
        if (block == null) return null;
        Element img = block.selectFirst("img");
        if (img == null) return null;

        String src = img.attr("src");
        if (isBlank(src)) return null;

        String id = block.hasAttr("data-mailpiece-id")
                ? block.attr("data-mailpiece-id")
                : "mailpiece-" + counter;

        String sender = firstNonBlank(
                textOrNull(block.selectFirst(".sender")),
                deriveSenderFromAlt(img.attr("alt")),
                deriveSenderFromContext(block));

        String summary = firstNonBlank(
                textOrNull(block.selectFirst(".summary")),
                deriveSummaryFromAlt(img.attr("alt")));

        OffsetDateTime received = payload.receivedAt() != null ? payload.receivedAt() : defaultDate;

        // Resolve CID references
        src = resolveCidReference(src, payload.inlineCidData());

        return new MailPiece(
                id,
                sender,
                summary,
                src,
                received,
                ActionLinks.defaults(null)
        );
    }

    private MailPiece toMailPieceFromImg(Element img, GmailDigestPayload payload, OffsetDateTime defaultDate, int counter) {
        if (img == null) return null;
        String src = img.attr("src");
        if (isBlank(src)) return null;

        String id = "mailpiece-" + counter;
        String sender = deriveSenderFromAlt(img.attr("alt"));
        String summary = deriveSummaryFromAlt(img.attr("alt"));
        OffsetDateTime received = payload.receivedAt() != null ? payload.receivedAt() : defaultDate;

        // Resolve CID references
        src = resolveCidReference(src, payload.inlineCidData());

        return new MailPiece(
                id,
                sender,
                summary,
                src,
                received,
                ActionLinks.defaults(null)
        );
    }

    private String deriveSenderFromAlt(String alt) {
        if (isBlank(alt)) return null;
        Matcher matcher = FROM_PATTERN.matcher(alt);
        if (matcher.find()) {
            return matcher.group(1).trim();
        }
        return null;
    }

    private String deriveSummaryFromAlt(String alt) {
        if (isBlank(alt)) return null;
        return alt.replaceAll("(?i)image of\\s*", "").trim();
    }

    private String deriveSenderFromContext(Element block) {
        if (block == null) return null;
        Element label = block.selectFirst("strong:matchesOwn((?i)from)");
        if (label != null) {
            return label.text().replaceFirst("(?i)from\\s*", "").trim();
        }
        return null;
    }

    private OffsetDateTime parseToOffset(String value) {
        if (isBlank(value)) return null;
        String candidate = value.trim();
        try {
            return OffsetDateTime.parse(candidate);
        } catch (DateTimeParseException ignore) {
            try {
                return ZonedDateTime.parse(candidate, RFC1123).toOffsetDateTime();
            } catch (DateTimeParseException ignore2) {
                for (DateTimeFormatter formatter : LOCAL_DATE_FORMATS) {
                    try {
                        LocalDate localDate = LocalDate.parse(candidate, formatter);
                        return localDate.atStartOfDay(ZoneOffset.UTC).toOffsetDateTime();
                    } catch (DateTimeParseException ignored3) {
                        // keep trying
                    }
                }
                try {
                    LocalDateTime localDateTime = LocalDateTime.parse(candidate);
                    return localDateTime.atZone(ZoneId.systemDefault()).toOffsetDateTime();
                } catch (DateTimeParseException ignore4) {
                    return null;
                }
            }
        }
    }

    private String extractTrackingNumber(String text) {
        if (isBlank(text)) return null;
        Matcher matcher = TRACKING_PATTERN.matcher(text);
        return matcher.find() ? matcher.group(1) : null;
    }

    private String textOrNull(Element element) {
        return element == null ? null : element.text();
    }

    private String firstNonBlank(String... candidates) {
        if (candidates == null) return null;
        for (String c : candidates) {
            if (!isBlank(c)) return c.trim();
        }
        return null;
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String resolveCidReference(String src, Map<String, String> cidMap) {
        if (isBlank(src) || cidMap == null || cidMap.isEmpty()) {
            return src;
        }

        // Check if it's a CID reference
        if (src.startsWith("cid:")) {
            String cid = normalizeCid(src.substring(4));
            String dataUrl = cidMap.get(cid);
            if (dataUrl != null) {
                return dataUrl;
            }
            // Try case-insensitive lookup
            for (Map.Entry<String, String> entry : cidMap.entrySet()) {
                if (normalizeCid(entry.getKey()).equals(cid)) {
                    return entry.getValue();
                }
            }
        }

        return src;
    }
}
