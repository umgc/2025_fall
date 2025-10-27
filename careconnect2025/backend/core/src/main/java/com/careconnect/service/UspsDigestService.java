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
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class UspsDigestService {

    private final EmailCredentialRepository emailCredentialRepository;
    private final UspsDigestCacheRepo cacheRepo;
    private final GmailClient gmailClient;
    private final GmailParser gmailParser;
    private final OutlookClient outlookClient;
    private final OutlookParser outlookParser;
    private final TokenCryptor tokenCryptor;

    private final ObjectMapper om = new ObjectMapper();

    public Optional<UspsDigest> digestForUserAndDate(String userId, LocalDate date) {
        System.out.println("[UspsDigestService] Starting digestForUserAndDate for userId: " + userId + ", date: " + date);

        // 1) Check cache for this specific date
        var cached = cacheRepo.findByUserIdAndDigestDate(userId, date);
        if (cached.isPresent()) {
            System.out.println("[UspsDigestService] Found cached digest for date, returning from cache");
            try {
                return Optional.of(om.readValue(cached.get().getPayloadJson(), UspsDigest.class));
            } catch (Exception e) {
                System.err.println("[UspsDigestService] Cache deserialization failed: " + e.getMessage());
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
        System.out.println("[UspsDigestService] Fetching from Gmail for date: " + date);
        var g = emailCredentialRepository.findFirstByUserIdAndProvider(userId, EmailCredential.Provider.GMAIL);
        if (g.isPresent()) {
            System.out.println("[UspsDigestService] Gmail credentials found, attempting to fetch from Gmail");
            try {
                var at = tokenCryptor.decrypt(g.get().getAccessTokenEnc());
                System.out.println("[UspsDigestService] Token decrypted successfully, calling Gmail API");
                var raw = gmailClient.fetchDigestForDate(at, date);
                if (raw.isPresent()) {
                    System.out.println("[UspsDigestService] Raw Gmail data found, parsing...");
                    var digest = gmailParser.toDomain(raw.get());
                    if (digest != null) {
                        System.out.println("[UspsDigestService] Gmail parsing successful, caching and returning");
                        cacheForDate(userId, digest, date);
                        return Optional.of(digest);
                    } else {
                        System.out.println("[UspsDigestService] Gmail parsing returned null");
                    }
                } else {
                    System.out.println("[UspsDigestService] No raw Gmail data found for date " + date);
                }
            } catch (Exception e) {
                System.err.println("[UspsDigestService] Gmail processing failed: " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            System.out.println("[UspsDigestService] No Gmail credentials found");
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
                System.err.println("[UspsDigestService] Outlook processing failed: " + e.getMessage());
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
            c.setPayloadJson(serialize(d));
            // Don't set expiration for historical data - keep it forever
            c.setExpiresAt(Instant.now().plus(Duration.ofDays(365 * 10))); // 10 years
            cacheRepo.save(c);
        } catch (Exception ignored) {}
    }

    private void cache(String userId, UspsDigest d) {
        try {
            var c = new UspsDigestCache();
            c.setUserId(userId);
            c.setDigestDate(d.getDigestDate() != null ? d.getDigestDate().toInstant() : Instant.now());
            c.setPayloadJson(serialize(d));
            c.setExpiresAt(Instant.now().plus(Duration.ofHours(6)));
            cacheRepo.save(c);
        } catch (Exception ignored) {}
    }

    private String serialize(UspsDigest d) {
        try { return om.writeValueAsString(d); } catch (Exception e) { return "{}"; }
    }

    private UspsDigest mockDigest() {
        var now = OffsetDateTime.now(ZoneOffset.UTC);
        var tracking = "9400100000000000000000";

        var pkg = PackageItem.builder()
                .trackingNumber(tracking)
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

    @Transactional
    public void clearCache(String userId) {
        try {
            var deleted = cacheRepo.deleteByUserId(userId);
            System.out.println("[UspsDigestService] Cleared " + deleted + " cache entries for userId: " + userId);
        } catch (Exception e) {
            System.err.println("[UspsDigestService] Failed to clear cache: " + e.getMessage());
        }
    }
}
