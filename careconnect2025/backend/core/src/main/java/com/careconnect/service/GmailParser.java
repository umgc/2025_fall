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
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
public class GmailParser {

    private static final Pattern TRACKING_PATTERN = Pattern.compile("(\\d{10,})");
    private static final Pattern FROM_PATTERN = Pattern.compile("(?i)(?:from|sender)[:\\s]+(.+)");
    private static final Pattern EXPECTED_PATTERN = Pattern.compile("Expected Delivery(?: Day)?:\\s*(.+)", Pattern.CASE_INSENSITIVE);
    private static final Pattern DIGEST_HEADING_PATTERN = Pattern.compile("(?i)Daily Digest(?: for)?\\s*(.*)");
    private static final DateTimeFormatter RFC1123 = DateTimeFormatter.RFC_1123_DATE_TIME;
    private static final DateTimeFormatter[] LOCAL_DATE_FORMATS = new DateTimeFormatter[]{
            DateTimeFormatter.ofPattern("EEEE, MMMM d, yyyy", Locale.US),
            DateTimeFormatter.ofPattern("MMMM d, yyyy", Locale.US),
            DateTimeFormatter.ofPattern("M/d/yyyy", Locale.US)
    };
    private static final String PLACEHOLDER_IMAGE =
            "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nMTIwJyBoZWlnaHQ9JzgwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnPiAgPHJlY3QgeD0nMCcgeT0nMCcgd2lkdGg9JzEyMCcgaGVpZ2h0PSc4MCcgcng9JzgnIHJ5PSc4JyBmaWxsPSIjZTRlNGU0Ii8+ICA8cmVjdCB4PSc4JyB5PScxNScgd2lkdGg9JzEwNCcgaGVpZ2h0PSc1MCcgcng9JzYnIHJ5PSc2JyBmaWxsPSIjZmZmIi8+ICA8cGF0aCBkPSdNMTAgMjBsNDggMzAgNDgtMzAnIGZpbGw9JyNkZGQnIHN0cm9rZT0nI2NjYycgc3Ryb2tlLXdpZHRoPScyJyBzdHJva2UtbGluZWNhcD0ncm91bmQnIHJ4PSc2JyByeT0nNicvPiAgPHRleHQgeD0nNjAnIHk9JzQ2JyB0ZXh0LWFuY2hvcj0nbWlkZGxlJyBmb250LXNpemU9JzEyJyBmb250LWZhbWlseT0nQXJpYWwnIGZpbGw9JyM2NjYnPkltYWdlIG5vdCBhdmFpbGFibGU8L3RleHQ+PC9zdmc+";

    public UspsDigest toDomain(GmailDigestPayload payload) {
        if (payload == null) return null;

        String htmlBody = payload.htmlBody() == null ? "" : payload.htmlBody();
        System.out.println("[GmailParser] Processing HTML body length: " + htmlBody.length());

        Document doc = Jsoup.parse(htmlBody);
        inlineCidImages(doc, payload.inlineCidData());

        OffsetDateTime digestDate = resolveDigestDate(doc, payload.receivedAt());
        int expectedMailCount = parseMailCount(doc);
        int expectedPackageCount = parsePackageCount(doc);

        List<PackageItem> packages = extractPackages(doc, digestDate);
        List<MailPiece> mailPieces = extractMailPieces(doc, payload, digestDate);

        mailPieces = deduplicateMailPieces(mailPieces);

        if (expectedMailCount <= 0 && !mailPieces.isEmpty()) {
            expectedMailCount = mailPieces.size();
        }

        for (int i = 0; i < mailPieces.size(); i++) {
            MailPiece mp = mailPieces.get(i);
            if (mp == null) continue;
            String thumb = mp.getThumbnailUrl();
            String thumbInfo;
            if (thumb == null) {
                thumbInfo = "null";
            } else if (thumb.startsWith("cid:")) {
                thumbInfo = "cid:" + thumb;
            } else {
                thumbInfo = "len=" + thumb.length();
            }
            System.out.println("[GmailParser] mailPiece " + i + " id=" + mp.getId() + ", sender=" + mp.getSender() + ", thumb=" + thumbInfo);
        }

        System.out.println("[GmailParser] Expected mail count: " + expectedMailCount + ", parsed mail pieces: " + mailPieces.size());
        System.out.println("[GmailParser] Expected package count: " + expectedPackageCount + ", parsed packages: " + packages.size());

        if (expectedMailCount > 0 && mailPieces.size() > expectedMailCount) {
            System.out.println("[GmailParser] Trimming mail pieces from " + mailPieces.size() + " to expected count " + expectedMailCount);
            mailPieces = new ArrayList<>(mailPieces.subList(0, expectedMailCount));
        }
        if (expectedPackageCount > 0 && packages.size() > expectedPackageCount) {
            System.out.println("[GmailParser] Trimming packages from " + packages.size() + " to expected count " + expectedPackageCount);
            packages = new ArrayList<>(packages.subList(0, expectedPackageCount));
        }
        if (expectedMailCount > 0 && mailPieces.size() < expectedMailCount) {
            int missing = expectedMailCount - mailPieces.size();
            System.out.println("[GmailParser] Adding " + missing + " placeholder mail pieces to match expected count");
            OffsetDateTime received = payload.receivedAt() != null ? payload.receivedAt() : digestDate;
            for (int i = 1; i <= missing; i++) {
                String id = "mail-placeholder-" + (mailPieces.size() + 1);
                mailPieces.add(createPlaceholderMailPiece(id, received));
            }
        }

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

        for (Element img : doc.select("img[src^=cid:], img[data-src^=cid:], img[data-lazy-src^=cid:], img[data-original^=cid:]")) {
            String raw = firstNonBlank(
                    img.attr("src"),
                    img.attr("data-src"),
                    img.attr("data-lazy-src"),
                    img.attr("data-original"));
            if (isBlank(raw) || !raw.contains(":")) {
                continue;
            }
            String cid = normalizeCid(raw.substring(raw.indexOf(':') + 1));
            String dataUrl = lookup.get(cid);
            if (dataUrl != null) {
                if (!isBlank(img.attr("src")) && img.attr("src").startsWith("cid:")) {
                    img.attr("src", dataUrl);
                }
                if (!isBlank(img.attr("data-src")) && img.attr("data-src").startsWith("cid:")) {
                    img.attr("data-src", dataUrl);
                }
                if (!isBlank(img.attr("data-lazy-src")) && img.attr("data-lazy-src").startsWith("cid:")) {
                    img.attr("data-lazy-src", dataUrl);
                }
                if (!isBlank(img.attr("data-original")) && img.attr("data-original").startsWith("cid:")) {
                    img.attr("data-original", dataUrl);
                }
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
        var packageElements = doc.select(".package, [data-package], article:has(.tracking-number), table:has(.tracking-number)");
        System.out.println("[GmailParser] Found " + packageElements.size() + " potential package elements");
        for (Element pkg : packageElements) {
            String rawTracking = firstNonBlank(
                    pkg.attr("data-tracking-number"),
                    textOrNull(pkg.selectFirst("[data-tracking-number]")),
                    textOrNull(pkg.selectFirst(".tracking-number")),
                    extractTrackingNumber(pkg.text()),
                    extractTrackingNumber(textOrNull(pkg.selectFirst("a[href*='Track']"))));
            String trackUrl = findTrackUrl(pkg);
            if (isBlank(rawTracking) && !isBlank(trackUrl)) {
                rawTracking = extractTrackingNumber(trackUrl);
            }
            String normalizedTracking = normalizeTracking(rawTracking);
            if (isBlank(normalizedTracking) || !seen.add(normalizedTracking)) continue;

            OffsetDateTime expected = parseToOffset(extractExpectedText(pkg));
            if (expected == null) expected = digestDate;
            String sender = extractSender(pkg);

            String displayTracking = !isBlank(rawTracking) ? rawTracking.trim() : normalizedTracking;

            items.add(PackageItem.builder()
                    .trackingNumber(displayTracking)
                    .sender(sender)
                    .expectedDeliveryDate(expected)
                    .actionLinks(ActionLinks.defaults(trackUrl))
                    .build());
        }

        if (!items.isEmpty()) return items;

        System.out.println("[GmailParser] No packages found with structured selectors, trying text search for 'Tracking Number'");
        var trackingElements = doc.select("*:matchesOwn((?i)Tracking Number)");
        System.out.println("[GmailParser] Found " + trackingElements.size() + " elements containing 'Tracking Number'");

        for (Element element : trackingElements) {
            String rawTracking = extractTrackingNumber(element.text());
            Element context = element.parent() != null ? element.parent() : element;
            OffsetDateTime expected = parseToOffset(extractExpectedText(context));
            if (expected == null) expected = digestDate;
            String trackUrl = findTrackUrl(context);

            String sender = extractSender(context);

            if (isBlank(rawTracking) && !isBlank(trackUrl)) {
                rawTracking = extractTrackingNumber(trackUrl);
            }
            String normalizedTracking = normalizeTracking(rawTracking);
            if (isBlank(normalizedTracking) || !seen.add(normalizedTracking)) continue;

            String displayTracking = !isBlank(rawTracking) ? rawTracking.trim() : normalizedTracking;

            items.add(PackageItem.builder()
                    .trackingNumber(displayTracking)
                    .sender(sender)
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

                java.util.regex.Pattern itemPattern = java.util.regex.Pattern.compile("(\\d+)\\s*item", java.util.regex.Pattern.CASE_INSENSITIVE);
                java.util.regex.Matcher itemMatcher = itemPattern.matcher(text);

                int count = -1;
                if (itemMatcher.find()) {
                    count = parseIntSafe(itemMatcher.group(1));
                }

                if (count <= 0) {
                    java.util.regex.Matcher numberMatcher = java.util.regex.Pattern.compile("(\\d+)").matcher(text.replaceAll("\\s+", ""));
                    if (numberMatcher.find()) {
                        count = Math.max(1, parseIntSafe(numberMatcher.group(1)));
                    }
                }

                if (count <= 0) {
                    count = 1; // Fallback to at least one package
                }

                if (count > 0) {
                    System.out.println("[GmailParser] Creating " + count + " summary packages");
                    for (int i = 1; i <= count && i <= 5; i++) {
                        items.add(PackageItem.builder()
                                .trackingNumber("USPS-SUMMARY-" + i + "-" + System.currentTimeMillis())
                                .sender("USPS Package")
                                .expectedDeliveryDate(digestDate)
                                .actionLinks(ActionLinks.defaults("https://informeddelivery.usps.com/box/dashboard"))
                                .build());
                    }
                    break;
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
            return sanitizeSender(matcher.group(1));
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
            if (isMarketingElement(block)) {
                continue;
            }
            MailPiece piece = toMailPiece(block, payload, defaultDate, counter++);
            if (piece != null) {
                pieces.add(piece);
            }
        }

        if (pieces.isEmpty()) {
            System.out.println("[GmailParser] No structured mail pieces found, looking for fallback images");
            var imgElements = doc.select("#mailpieces img[src^=data:], #mailpieces img[src^=https], "
                    + "#mailpieces img[src^=cid:], "
                    + "#mailpieces img[data-src^=data:], #mailpieces img[data-src^=https], #mailpieces img[data-src^=cid:], "
                    + "#mailpieces img[data-lazy-src^=data:], #mailpieces img[data-lazy-src^=https], #mailpieces img[data-lazy-src^=cid:], "
                    + "#mailpieces img[data-original^=data:], #mailpieces img[data-original^=https], #mailpieces img[data-original^=cid:], "
                    + "img[alt*=mailpiece]");
            System.out.println("[GmailParser] Found " + imgElements.size() + " potential mail piece images");

            // Look for any CID images that might be mail pieces
            var cidImages = doc.select("img[src^=cid:]");
            System.out.println("[GmailParser] Found " + cidImages.size() + " CID images");

            // Try to convert any CID images into mail pieces
            int cidIdx = 1;
            for (Element img : cidImages) {
                if (isMarketingElement(img)) {
                    continue;
                }
                MailPiece piece = toMailPieceFromImg(img, payload, defaultDate, cidIdx++);
                if (piece != null) {
                    pieces.add(piece);
                }
            }

            int idx = 1;
            for (Element img : imgElements) {
                if (isMarketingElement(img)) {
                    continue;
                }
                MailPiece piece = toMailPieceFromImg(img, payload, defaultDate, idx++);
                if (piece != null) {
                    pieces.add(piece);
                }
            }
        }
        return pieces;
    }

    private List<MailPiece> deduplicateMailPieces(List<MailPiece> pieces) {
        if (pieces == null || pieces.isEmpty()) {
            return pieces;
        }

        List<MailPiece> filtered = new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();

        for (MailPiece piece : pieces) {
            if (piece == null) {
                continue;
            }

            String id = piece.getId();
            boolean placeholder = id != null && (id.startsWith("mail-summary-") || id.startsWith("mail-placeholder-"));
            String key = null;
            if (!isBlank(id)) {
                key = "id:" + id.trim().toLowerCase(Locale.ROOT);
            } else {
                String thumb = piece.getThumbnailUrl();
                String subject = piece.getSubject();
                String sender = piece.getSender();
                if (!isBlank(thumb) || !isBlank(subject) || !isBlank(sender)) {
                    key = "content:" + safeLower(thumb) + "|" + safeLower(subject) + "|" + safeLower(sender);
                }
            }

            if (key == null) {
                key = "rand:" + UUID.randomUUID();
            }

            if (!seen.add(key)) {
                continue;
            }

            if (placeholder) {
                continue;
            }

            filtered.add(piece);
        }

        if (filtered.isEmpty()) {
            return pieces.stream()
                    .filter(Objects::nonNull)
                    .limit(1)
                    .collect(Collectors.toList());
        }

        return filtered;
    }

    private MailPiece toMailPiece(Element block, GmailDigestPayload payload, OffsetDateTime defaultDate, int counter) {
        if (block == null) return null;
        Element img = block.selectFirst("img");
        if (img == null) return null;

        String rawSrc = firstNonBlank(
                img.attr("src"),
                img.attr("data-src"),
                img.attr("data-lazy-src"),
                img.attr("data-original"));
        String src = resolveCidReference(rawSrc, payload.inlineCidData());
        if (isBlank(src)) return null;

        String id = block.hasAttr("data-mailpiece-id")
                ? block.attr("data-mailpiece-id")
                : "mailpiece-" + counter;

        String alt = img.attr("alt");

        String sender = firstNonBlank(
                textOrNull(block.selectFirst(".sender")),
                deriveSenderFromAlt(alt),
                deriveSenderFromContext(block));
        if (isBlank(sender)) {
            sender = extractSender(block);
        }

        String summary = firstNonBlank(
                textOrNull(block.selectFirst(".summary")),
                deriveSummaryFromAlt(alt));

        if (isMarketingText(alt) || isMarketingText(sender) || isMarketingText(summary)) {
            return null;
        }

        OffsetDateTime received = payload.receivedAt() != null ? payload.receivedAt() : defaultDate;

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
        String rawSrc = firstNonBlank(
                img.attr("src"),
                img.attr("data-src"),
                img.attr("data-lazy-src"),
                img.attr("data-original"));
        String src = resolveCidReference(rawSrc, payload.inlineCidData());
        if (isBlank(src)) return null;

        String id = "mailpiece-" + counter;
        String alt = img.attr("alt");
        String sender = deriveSenderFromAlt(alt);
        if (isBlank(sender)) {
            sender = extractSender(img.parent());
        }
        String summary = deriveSummaryFromAlt(alt);
        OffsetDateTime received = payload.receivedAt() != null ? payload.receivedAt() : defaultDate;

        if (isMarketingText(alt) || isMarketingText(sender) || isMarketingText(summary)) {
            return null;
        }

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
            return sanitizeSender(matcher.group(1));
        }
        return null;
    }

    private String deriveSummaryFromAlt(String alt) {
        if (isBlank(alt)) return null;
        return alt.replaceAll("(?i)image of\\s*", "").trim();
    }

    private String deriveSenderFromContext(Element block) {
        if (block == null) return null;
        Element label = block.selectFirst("strong:matchesOwn((?i)(from|sender))");
        if (label != null) {
            return label.text().replaceFirst("(?i)(?:from|sender)\\s*", "").trim();
        }
        return null;
    }

    private String extractSender(Element context) {
        if (context == null) return null;

        String candidate = extractSenderFromText(context.ownText());
        if (!isBlank(candidate)) {
            return candidate;
        }

        candidate = deriveSenderFromContext(context);
        if (!isBlank(candidate)) {
            return candidate;
        }

        for (Element child : context.select("*")) {
            candidate = extractSenderFromText(child.ownText());
            if (!isBlank(candidate)) {
                return candidate;
            }
        }

        Element sibling = context.previousElementSibling();
        int hops = 0;
        while (sibling != null && hops++ < 3) {
            candidate = extractSenderFromText(sibling.text());
            if (!isBlank(candidate)) {
                return candidate;
            }
            sibling = sibling.previousElementSibling();
        }

        return null;
    }

    private String extractSenderFromText(String text) {
        if (isBlank(text)) {
            return null;
        }
        Matcher matcher = FROM_PATTERN.matcher(text);
        if (matcher.find()) {
            return sanitizeSender(matcher.group(1));
        }
        return null;
    }

    private boolean isMarketingElement(Element element) {
        Element cursor = element;
        int depth = 0;
        while (cursor != null && depth++ < 6) {
            String id = cursor.id();
            String classes = cursor.className();
            if (containsMarketingKeyword(id) || containsMarketingKeyword(classes)) {
                return true;
            }
            cursor = cursor.parent();
        }
        return false;
    }

    private boolean containsMarketingKeyword(String value) {
        if (isBlank(value)) {
            return false;
        }
        String lower = value.toLowerCase(Locale.ROOT);
        return lower.contains("campaign")
            || lower.contains("ridealong")
            || lower.contains("promo")
            || lower.contains("sat");
    }

    private boolean isMarketingText(String value) {
        if (isBlank(value)) {
            return false;
        }
        String lower = value.toLowerCase(Locale.ROOT);
        return lower.contains("campaign")
            || lower.contains("ridealong")
            || lower.contains("promotion")
            || lower.contains("learn more about your mail")
            || lower.contains("tru") && lower.contains("stage");
    }

    private String sanitizeSender(String value) {
        if (isBlank(value)) {
            return null;
        }
        String cleaned = value
                .replaceAll("(?i)tracking number.*", "")
                .replaceAll("(?i)expected delivery.*", "")
                .replaceAll("[\\r\\n]+", " ")
                .trim();
        if (cleaned.isEmpty()) {
            return null;
        }
        return cleaned;
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
        String digitsOnly = text.replaceAll("[^0-9]", "");
        if (digitsOnly.length() >= 10) {
            return digitsOnly;
        }
        Matcher matcher = TRACKING_PATTERN.matcher(text);
        return matcher.find() ? matcher.group(1) : null;
    }

    private String normalizeTracking(String value) {
        if (isBlank(value)) {
            return null;
        }
        String digitsOnly = value.replaceAll("[^0-9]", "");
        return digitsOnly.length() >= 10 ? digitsOnly : value.trim();
    }

    private int parseIntSafe(String value) {
        if (isBlank(value)) {
            return -1;
        }
        try {
            return Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            return -1;
        }
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

    private String safeLower(String value) {
        return isBlank(value) ? "" : value.trim().toLowerCase(Locale.ROOT);
    }

    private MailPiece createPlaceholderMailPiece(String id, OffsetDateTime receivedAt) {
        OffsetDateTime timestamp = receivedAt != null ? receivedAt : OffsetDateTime.now(ZoneOffset.UTC);
        return new MailPiece(
                id,
                "USPS Mail Piece",
                "Image not available",
                PLACEHOLDER_IMAGE,
                timestamp,
                ActionLinks.defaults("https://informeddelivery.usps.com/box/dashboard")
        );
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private int parseMailCount(Document doc) {
        Element countEl = doc.selectFirst("#total-mailpieces, #total-mailpieces-secondary, #today-mailitem-number");
        if (countEl != null) {
            int parsed = parseIntSafe(countEl.text());
            if (parsed > 0) {
                return parsed;
            }
        }
        Element header = doc.selectFirst("p:matches(You have \\d+ mailpiece)");
        if (header != null) {
            Matcher matcher = Pattern.compile("You have \\s*(\\d+)").matcher(header.text());
            if (matcher.find()) {
                return parseIntSafe(matcher.group(1));
            }
        }
        Element mailHeader = doc.selectFirst("*:matchesOwn((?i)mail ?pieces?.*\\d)");
        if (mailHeader != null) {
            Matcher matcher = Pattern.compile("(\\d+)").matcher(mailHeader.text());
            if (matcher.find()) {
                return parseIntSafe(matcher.group(1));
            }
        }
        return -1;
    }

    private int parsePackageCount(Document doc) {
        Element countEl = doc.selectFirst("#total-packages, #total-packages-secondary, #today-package-item-number, #onetwodays-package-item-number, #awaiting-package-item-number");
        if (countEl != null) {
            int parsed = parseIntSafe(countEl.text());
            if (parsed >= 0) {
                return parsed;
            }
        }
        return -1;
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
