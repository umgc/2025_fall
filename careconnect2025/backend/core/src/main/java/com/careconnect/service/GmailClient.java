package com.careconnect.service;

import com.careconnect.dto.GmailDigestPayload;
import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class GmailClient {

    private final WebClient webClient = WebClient.builder()
            .baseUrl("https://gmail.googleapis.com/gmail/v1")
            .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
            .build();

    /**
     * Fetch USPS digest email for a specific date.
     */
    public Optional<GmailDigestPayload> fetchDigestForDate(String accessToken, LocalDate date) {
        try {
            // Format the date for Gmail search (e.g., "2025/10/27")
            String formattedDate = date.format(DateTimeFormatter.ofPattern("yyyy/M/d"));
            String query = "from:USPSInformeddelivery@email.informeddelivery.usps.com subject:(Your Daily Digest) after:" +
                    formattedDate + " before:" + date.plusDays(1).format(DateTimeFormatter.ofPattern("yyyy/M/d"));

            System.out.println("[GmailClient] Searching for digest with query: " + query);

            JsonNode search = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/users/me/messages")
                            .queryParam("q", query)
                            .queryParam("maxResults", 10)
                            .build())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();

            if (search == null || !search.has("messages")) {
                System.out.println("[GmailClient] No messages found for date " + date);
                return Optional.empty();
            }

            // Find the digest closest to the target date
            GmailDigestPayload bestMatch = null;
            long bestDateDiff = Long.MAX_VALUE;

            Iterator<JsonNode> iterator = search.get("messages").elements();
            while (iterator.hasNext()) {
                JsonNode messageRef = iterator.next();
                String messageId = messageRef.path("id").asText(null);
                if (messageId == null) continue;

                JsonNode message = webClient.get()
                        .uri("/users/me/messages/{id}?format=full", messageId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                        .retrieve()
                        .bodyToMono(JsonNode.class)
                        .block();

                if (message == null) continue;

                long internalDate = message.path("internalDate").asLong(0);
                if (internalDate == 0) continue;

                // Check if this message is from the target date
                OffsetDateTime messageDate = OffsetDateTime.ofInstant(
                        Instant.ofEpochMilli(internalDate), ZoneOffset.UTC);
                LocalDate messageDateLocal = messageDate.toLocalDate();

                if (messageDateLocal.equals(date)) {
                    GmailDigestPayload payload = buildPayload(accessToken, messageId, message);
                    if (payload != null) {
                        long dateDiff = Math.abs(internalDate - date.atStartOfDay().toInstant(ZoneOffset.UTC).toEpochMilli());
                        if (dateDiff < bestDateDiff) {
                            bestDateDiff = dateDiff;
                            bestMatch = payload;
                        }
                    }
                }
            }

            return Optional.ofNullable(bestMatch);
        } catch (Exception e) {
            System.err.println("[GmailClient] Error fetching digest for date " + date + ": " + e.getMessage());
            e.printStackTrace();
            return Optional.empty();
        }
    }

    /**
     * Fetch the latest USPS digest email along with inline CID assets.
     */
    public Optional<GmailDigestPayload> fetchLatestDigest(String accessToken) {
        try {
            JsonNode search = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/users/me/messages")
                            .queryParam("q", "from:USPSInformeddelivery@email.informeddelivery.usps.com subject:(Your Daily Digest) newer_than:7d")
                            .queryParam("maxResults", 5)
                            .build())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();

            if (search == null || !search.has("messages")) {
                return Optional.empty();
            }

            GmailDigestPayload newestPayload = null;
            long newestDate = -1;

            Iterator<JsonNode> iterator = search.get("messages").elements();
            while (iterator.hasNext()) {
                JsonNode messageRef = iterator.next();
                String messageId = messageRef.path("id").asText(null);
                if (messageId == null) continue;

                JsonNode message = webClient.get()
                        .uri("/users/me/messages/{id}?format=full", messageId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                        .retrieve()
                        .bodyToMono(JsonNode.class)
                        .block();

                if (message == null) continue;
                GmailDigestPayload payload = buildPayload(accessToken, messageId, message);
                if (payload == null) continue;

                long internalDate = message.path("internalDate").asLong(0);
                if (internalDate > newestDate) {
                    newestDate = internalDate;
                    newestPayload = payload;
                }
            }

            return Optional.ofNullable(newestPayload);
        } catch (Exception e) {
            e.printStackTrace();
            return Optional.empty();
        }
    }

    private GmailDigestPayload buildPayload(String accessToken, String messageId, JsonNode message) {
        Map<String, String> cidMap = new HashMap<>();
        String html = extractHtml(accessToken, messageId, message.path("payload"), cidMap);
        if (html == null || html.isBlank()) {
            return null;
        }
        OffsetDateTime receivedAt = resolveReceivedAt(message);
        return new GmailDigestPayload(html, cidMap, receivedAt);
    }

    private OffsetDateTime resolveReceivedAt(JsonNode message) {
        long internalMs = message.path("internalDate").asLong(0);
        if (internalMs > 0) {
            return OffsetDateTime.ofInstant(Instant.ofEpochMilli(internalMs), ZoneOffset.UTC);
        }
        return OffsetDateTime.now(ZoneOffset.UTC);
    }

    private String extractHtml(String accessToken, String messageId, JsonNode part, Map<String, String> cidMap) {
        if (part == null || part.isMissingNode()) return null;

        collectInlinePart(accessToken, messageId, part, cidMap);

        JsonNode body = part.path("body");
        String mimeType = part.path("mimeType").asText("");
        if ("text/html".equalsIgnoreCase(mimeType) && body.has("data")) {
            return decodeToString(body.path("data").asText());
        }

        if (body.has("data") && !body.path("data").asText().isBlank() && mimeType.startsWith("multipart/")) {
            // multipart bodies occasionally inline the HTML directly
            String candidate = decodeToString(body.path("data").asText());
            if (candidate.toLowerCase().contains("<html")) {
                return candidate;
            }
        }

        for (JsonNode child : part.path("parts")) {
            String html = extractHtml(accessToken, messageId, child, cidMap);
            if (html != null) return html;
        }
        return null;
    }

    private void collectInlinePart(String accessToken, String messageId, JsonNode part, Map<String, String> cidMap) {
        String contentId = header(part, "Content-ID");
        if (contentId == null) return;

        contentId = contentId.replace("<", "").replace(">", "").trim();
        if (cidMap.containsKey(contentId)) return;

        String mimeType = part.path("mimeType").asText("application/octet-stream");
        JsonNode body = part.path("body");
        String data = body.path("data").asText(null);

        if ((data == null || data.isBlank()) && body.has("attachmentId")) {
            String attachmentId = body.path("attachmentId").asText();
            data = fetchAttachment(accessToken, messageId, attachmentId);
        }

        if (data != null && !data.isBlank()) {
            byte[] decoded = decode(data);
            String dataUrl = "data:" + mimeType + ";base64," + Base64.getEncoder().encodeToString(decoded);
            cidMap.put(contentId, dataUrl);
            cidMap.putIfAbsent(contentId.toLowerCase(Locale.ROOT), dataUrl);
        }
    }

    private String header(JsonNode node, String name) {
        for (JsonNode header : node.path("headers")) {
            if (name.equalsIgnoreCase(header.path("name").asText())) {
                return header.path("value").asText();
            }
        }
        return null;
    }

    private String fetchAttachment(String accessToken, String messageId, String attachmentId) {
        try {
            JsonNode attachment = webClient.get()
                    .uri("/users/me/messages/{messageId}/attachments/{attachmentId}", messageId, attachmentId)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();
            if (attachment != null && attachment.has("data")) {
                return attachment.get("data").asText();
            }
        } catch (Exception e) {
            // best-effort; swallow so callers can still use partial payloads
            e.printStackTrace();
        }
        return null;
    }

    private byte[] decode(String data) {
        return Base64.getUrlDecoder().decode(data);
    }

    private String decodeToString(String data) {
        return new String(decode(data), StandardCharsets.UTF_8);
    }
}
