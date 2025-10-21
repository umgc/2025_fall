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

        Document doc = Jsoup.parse(payload.htmlBody() == null ? "" : payload.htmlBody());
        inlineCidImages(doc, payload.inlineCidData());

        OffsetDateTime digestDate = resolveDigestDate(doc, payload.receivedAt());
        List<PackageItem> packages = extractPackages(doc, digestDate);
        List<MailPiece> mailPieces = extractMailPieces(doc, payload, digestDate);

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

        for (Element pkg : doc.select(".package, [data-package], article:has(.tracking-number)")) {
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

        for (Element element : doc.select("*:matchesOwn((?i)Tracking Number)")) {
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

        for (Element block : doc.select("#mailpieces .mailpiece, [data-mailpiece-id], .mailpiece")) {
            MailPiece piece = toMailPiece(block, payload, defaultDate, counter++);
            if (piece != null) {
                pieces.add(piece);
            }
        }

        if (pieces.isEmpty()) {
            int idx = 1;
            for (Element img : doc.select("#mailpieces img[src^=data:], #mailpieces img[src^=https], img[alt*=mailpiece]")) {
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
