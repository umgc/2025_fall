package com.careconnect.service;

import com.fasterxml.jackson.databind.JsonNode;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Optional;

@Component
@RequiredArgsConstructor
public class GmailClient {

    private final WebClient webClient = WebClient.builder()
            .baseUrl("https://gmail.googleapis.com/gmail/v1")
            .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
            .build();

    /**
     * Fetch the latest USPS digest email.
     */
    public Optional<String> fetchLatestDigest(String accessToken) {
        try {
            JsonNode search = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/users/me/messages")
                            .queryParam("q", "from:usps.com subject:(Informed Delivery Daily Digest) newer_than:7d")
                            .build())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();

            if (search == null || !search.has("messages")) {
                return Optional.empty();
            }

            String messageId = search.get("messages").get(0).get("id").asText();

            JsonNode message = webClient.get()
                    .uri("/users/me/messages/{id}?format=full", messageId)
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                    .retrieve()
                    .bodyToMono(JsonNode.class)
                    .block();

            if (message == null) return Optional.empty();
            return Optional.ofNullable(extractHtml(message));

        } catch (Exception e) {
            e.printStackTrace();
            return Optional.empty();
        }
    }

    private String extractHtml(JsonNode message) {
        var payload = message.path("payload");
        if (payload.has("body") && payload.path("body").has("data")) {
            return decode(payload.path("body").path("data").asText());
        }
        for (JsonNode part : payload.path("parts")) {
            if (part.path("mimeType").asText().equals("text/html")) {
                return decode(part.path("body").path("data").asText());
            }
        }
        return null;
    }

    private String decode(String data) {
        return new String(java.util.Base64.getUrlDecoder().decode(data));
    }
}
