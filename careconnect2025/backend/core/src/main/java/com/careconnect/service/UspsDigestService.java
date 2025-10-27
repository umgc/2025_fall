package com.careconnect.service;

import com.careconnect.model.ActionLinks;
import com.careconnect.model.EmailCredential;
import com.careconnect.model.MailPiece;
import com.careconnect.model.PackageItem;
import com.careconnect.model.UspsDigest;
import com.careconnect.model.UspsDigestCache;
import com.careconnect.repository.EmailCredentialRepository;
import com.careconnect.repository.UspsDigestCacheRepo;
import com.careconnect.security.TokenCryptor;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UspsDigestService {

    private static final Logger log = LoggerFactory.getLogger(UspsDigestService.class);

    private final EmailCredentialRepository emailCredentialRepository;
    private final UspsDigestCacheRepo cacheRepo;
    private final GmailClient gmailClient;
    private final GmailParser gmailParser;
    private final OutlookClient outlookClient;
    private final OutlookParser outlookParser;
    private final GoogleOAuthService googleOAuthService;
    private final TokenCryptor tokenCryptor;

    private final ObjectMapper om = new ObjectMapper()
        .registerModule(new JavaTimeModule())
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    public Optional<UspsDigest> digestForUserAndDate(String userId, LocalDate date) {
        // 1) Check cache for this specific date
        var cached = cacheRepo.findByUserIdAndDigestDate(userId, date);
        if (cached.isPresent()) {
            try {
                return Optional.of(om.readValue(cached.get().getPayloadJson(), UspsDigest.class));
            } catch (Exception e) {
                log.warn("Failed to deserialize cached USPS digest for user {} on {}", userId, date, e);
            }
        }

        // 2) Fetch from Gmail for the specific date
        return fetchDigestFromGmail(userId, date);
    }

    public Optional<UspsDigest> latestForUser(String userId) {
        return digestForUserAndDate(userId, LocalDate.now());
    }

    private Optional<UspsDigest> fetchDigestFromGmail(String userId, LocalDate date) {
        // Gmail
        var g = emailCredentialRepository.findFirstByUserIdAndProvider(userId, EmailCredential.Provider.GMAIL);
        if (g.isPresent()) {
            try {
                var credential = googleOAuthService.ensureFreshToken(g.get());
                var at = tokenCryptor.decrypt(credential.getAccessTokenEnc());
                var raw = gmailClient.fetchDigestForDate(at, date);
                if (raw.isPresent()) {
                    var digest = gmailParser.toDomain(raw.get());
                    if (digest != null) {
                        cacheForDate(userId, digest, date);
                        return Optional.of(digest);
                    }
                }
            } catch (Exception e) {
                log.warn("Gmail digest processing failed for user {} on {}", userId, date, e);
            }
        }

        // Outlook (similar logic)
        var o = emailCredentialRepository.findFirstByUserIdAndProvider(userId, EmailCredential.Provider.OUTLOOK);
        if (o.isPresent()) {
            try {
                var at = tokenCryptor.decrypt(o.get().getAccessTokenEnc());
                var raw = outlookClient.fetchDigestForDate(at, date);
                if (raw.isPresent()) {
                    var digest = outlookParser.toDomain(raw.get());
                    if (digest != null) {
                        cacheForDate(userId, digest, date);
                        return Optional.of(digest);
                    }
                }
            } catch (Exception e) {
                log.warn("Outlook digest processing failed for user {} on {}", userId, date, e);
            }
        }

        return Optional.empty();
    }

    private void cacheForDate(String userId, UspsDigest d, LocalDate date) {
        try {
            var c = new UspsDigestCache();
            c.setUserId(userId);
            c.setDigestDate(d.getDigestDate() != null ? d.getDigestDate().toInstant() :
                date.atStartOfDay().toInstant(ZoneOffset.UTC));

            String jsonPayload = serialize(d);

            c.setPayloadJson(jsonPayload);
            // Don't set expiration for historical data - keep it forever
            c.setExpiresAt(Instant.now().plus(Duration.ofDays(365 * 10))); // 10 years

            cacheRepo.save(c);
        } catch (Exception e) {
            log.warn("Failed to cache USPS digest for user {} on {}", userId, date, e);
        }
    }

    private void cache(String userId, UspsDigest d) {
        try {
            var c = new UspsDigestCache();
            c.setUserId(userId);
            c.setDigestDate(d.getDigestDate() != null ? d.getDigestDate().toInstant() : Instant.now());
            c.setPayloadJson(serialize(d));
            c.setExpiresAt(Instant.now().plus(Duration.ofHours(6)));
            cacheRepo.save(c);
        } catch (Exception e) {
            log.warn("Failed to cache latest USPS digest for user {}", userId, e);
        }
    }

    private String serialize(UspsDigest d) {
        try {
            return om.writeValueAsString(d);
        } catch (Exception e) {
            log.warn("Failed to serialize USPS digest payload", e);
            return "{}";
        }
    }

    private UspsDigest mockDigest() {
        var now = OffsetDateTime.now(ZoneOffset.UTC);
        var tracking = "9400100000000000000000";

        var pkg = PackageItem.builder()
                .trackingNumber(tracking)
                .sender("Informed Delivery")
                .expectedDeliveryDate(now.plusDays(1))
                .actionLinks(ActionLinks.defaults(
                        "https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=" + tracking))
                .build();

        var mp  = MailPiece.builder()
                .id("m-1")
                .sender("ACME Bank")
                .subject("Monthly statement")
                .thumbnailUrl("data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAnIGhlaWdodD0nMjAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHJlY3Qgd2lkdGg9JzQwJyBoZWlnaHQ9JzIwJyBmaWxsPSIjZGRkIi8+PC9zdmc+")
                .receivedAt(now)
                .actionLinks(ActionLinks.defaults("https://informeddelivery.usps.com/box/dashboard"))
                .build();

        return UspsDigest.builder()
                .digestDate(now)
                .mailPieces(List.of(mp))
                .packages(List.of(pkg))
                .build();
    }

    public List<Map<String, Object>> searchMailHistory(String userId, String keyword) {
        // Get all cached digests for the user
        var allCachedDigests = cacheRepo.findAllByUserId(userId);
        List<Map<String, Object>> results = new ArrayList<>();

        for (var cachedDigest : allCachedDigests) {
            try {
                var digest = om.readValue(cachedDigest.getPayloadJson(), UspsDigest.class);
                if (digest.getMailPieces() != null && !digest.getMailPieces().isEmpty()) {
                    for (var mailPiece : digest.getMailPieces()) {
                        if (matchesKeyword(mailPiece, keyword)) {
                            Map<String, Object> result = new HashMap<>();
                            result.put("id", mailPiece.getId());
                            result.put("sender", mailPiece.getSender());
                            result.put("summary", mailPiece.getSubject());
                            result.put("imageDataUrl", mailPiece.getThumbnailUrl());
                            result.put("deliveryDate", formatDeliveryDate(digest.getDigestDate()));
                            result.put("actions", Map.of("dashboard",
                                mailPiece.getActionLinks() != null ?
                                mailPiece.getActionLinks().getDashboard() :
                                "https://informeddelivery.usps.com/box/dashboard"));
                            result.put("type", "mail");
                            results.add(result);
                        }
                    }
                }

                if (digest.getPackages() != null && !digest.getPackages().isEmpty()) {
                    for (var pkg : digest.getPackages()) {
                        if (matchesKeyword(pkg, keyword)) {
                            Map<String, Object> result = new HashMap<>();
                            result.put("id", pkg.getTrackingNumber());
                            result.put("type", "package");
                            result.put("sender", firstNonBlank(pkg.getSender(), "USPS Package"));
                            result.put("summary", pkg.getTrackingNumber());
                            result.put("deliveryDate", formatDeliveryDate(pkg.getExpectedDeliveryDate()));
                            result.put("expectedDate", formatDeliveryDate(pkg.getExpectedDeliveryDate()));
                            result.put("expectedDateIso",
                                pkg.getExpectedDeliveryDate() != null ? pkg.getExpectedDeliveryDate().toString() : null);

                            if (pkg.getActionLinks() != null) {
                                Map<String, String> actions = new HashMap<>();
                                if (pkg.getActionLinks().getTrack() != null) {
                                    actions.put("track", pkg.getActionLinks().getTrack());
                                }
                                if (pkg.getActionLinks().getDashboard() != null) {
                                    actions.put("dashboard", pkg.getActionLinks().getDashboard());
                                }
                                if (pkg.getActionLinks().getDeliveryInstructions() != null) {
                                    actions.put("deliveryInstructions", pkg.getActionLinks().getDeliveryInstructions());
                                }
                                if (pkg.getActionLinks().getScheduleRedelivery() != null) {
                                    actions.put("scheduleRedelivery", pkg.getActionLinks().getScheduleRedelivery());
                                }
                                if (!actions.isEmpty()) {
                                    result.put("actions", actions);
                                }
                            }

                            result.put("trackingNumber", pkg.getTrackingNumber());
                            results.add(result);
                        }
                    }
                }
            } catch (Exception e) {
                log.warn("Failed to parse cached USPS digest for user {}", userId, e);
            }
        }

        // Sort by delivery date (newest first)
        results.sort((a, b) -> {
            String dateA = (String) a.get("deliveryDate");
            String dateB = (String) b.get("deliveryDate");
            return dateB.compareTo(dateA); // Reverse order for newest first
        });

        return results;
    }

    private boolean matchesKeyword(MailPiece mailPiece, String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return false;
        }

        String lowerKeyword = keyword.toLowerCase().trim();

        // Search in sender
        if (mailPiece.getSender() != null) {
            String senderLower = mailPiece.getSender().toLowerCase();
            if (senderLower.contains(lowerKeyword)) {
                return true;
            }
        }

        // Search in subject/summary
        if (mailPiece.getSubject() != null) {
            String subjectLower = mailPiece.getSubject().toLowerCase();
            if (subjectLower.contains(lowerKeyword)) {
                return true;
            }
        }

        return false;
    }

    private boolean matchesKeyword(PackageItem pkg, String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return false;
        }

        String lowerKeyword = keyword.toLowerCase().trim();

        if (pkg.getTrackingNumber() != null && pkg.getTrackingNumber().toLowerCase().contains(lowerKeyword)) {
            return true;
        }

        if (pkg.getSender() != null && pkg.getSender().toLowerCase().contains(lowerKeyword)) {
            return true;
        }

        if (pkg.getExpectedDeliveryDate() != null) {
            String expected = formatDeliveryDate(pkg.getExpectedDeliveryDate());
            if (expected.toLowerCase().contains(lowerKeyword)) {
                return true;
            }
        }

        return false;
    }

    private String firstNonBlank(String... candidates) {
        if (candidates == null) {
            return null;
        }
        for (String candidate : candidates) {
            if (candidate != null && !candidate.isBlank()) {
                return candidate;
            }
        }
        return null;
    }

    private String formatDeliveryDate(OffsetDateTime dateTime) {
        if (dateTime == null) {
            return "Unknown";
        }

        // Format as MM/dd/yyyy
        return String.format("%02d/%02d/%d",
            dateTime.getMonthValue(),
            dateTime.getDayOfMonth(),
            dateTime.getYear());
    }

    @Transactional
    public void clearCache(String userId) {
        try {
            cacheRepo.deleteByUserId(userId);
        } catch (Exception e) {
            log.warn("Failed to clear USPS digest cache for user {}", userId, e);
        }
    }
}
