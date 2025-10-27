package com.careconnect.service;

import com.careconnect.model.*;
import com.careconnect.repository.EmailCredentialRepo;
import com.careconnect.repository.USPSDigestCacheRepo;
import com.careconnect.security.TokenCryptor;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.*;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class USPSDigestService {
    private final EmailCredentialRepo credRepo;
    private final USPSDigestCacheRepo cacheRepo;
    private final GmailClient gmailClient;
    private final OutlookClient outlookClient;
    private final GmailParser gmailParser;
    private final OutlookParser outlookParser;
    private final TokenCryptor tokenCryptor;
    private final ObjectMapper om = new ObjectMapper();

    public Optional<USPSDigest> latestForUser(String userId) {
        // 1) cache
        var cached = cacheRepo.findFirstByUserIdAndExpiresAtAfterOrderByDigestDateDesc(userId, Instant.now());
        if (cached.isPresent()) {
            try {
                return Optional.of(om.readValue(cached.get().getPayloadJson(), USPSDigest.class));
            } catch (Exception ignored) {}
        }

        // 2) Gmail
        var g = credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.GMAIL);
        if (g.isPresent()) {
            var at = decrypt(g.get().getAccessTokenEnc());
            var raw = gmailClient.fetchLatestDigest(at);
            if (raw.isPresent()) {
                var digest = gmailParser.toDomain(raw.get());
                cache(userId, digest);
                return Optional.of(digest);
            }
        }

        // 3) Outlook
        var o = credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.OUTLOOK);
        if (o.isPresent()) {
            var at = decrypt(o.get().getAccessTokenEnc());
            var raw = outlookClient.fetchLatestDigest(at);
            if (raw.isPresent()) {
                var digest = outlookParser.toDomain(raw.get());
                cache(userId, digest);
                return Optional.of(digest);
            }
        }

        // 4) No mock data - return empty if no real data found
        return Optional.empty();
    }

    public Optional<USPSDigest> digestForDate(String userId, LocalDate date) {
        if (date == null) {
            return latestForUser(userId);
        }

        var start = date.atStartOfDay(ZoneOffset.UTC).toInstant();
        var end = date.plusDays(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        var now = Instant.now();

        var cached = cacheRepo.findFirstByUserIdAndDigestDateBetweenAndExpiresAtAfterOrderByDigestDateDesc(
                userId, start, end, now);
        if (cached.isPresent()) {
            try {
                return Optional.of(om.readValue(cached.get().getPayloadJson(), USPSDigest.class));
            } catch (Exception ignored) { }
        }

        var g = credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.GMAIL);
        if (g.isPresent()) {
            var at = decrypt(g.get().getAccessTokenEnc());
            var raw = gmailClient.fetchDigestForDate(at, date);
            if (raw.isPresent()) {
                var digest = gmailParser.toDomain(raw.get());
                cache(userId, digest, date);
                return Optional.of(digest);
            }
        }

        var o = credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.OUTLOOK);
        if (o.isPresent()) {
            var at = decrypt(o.get().getAccessTokenEnc());
            var raw = outlookClient.fetchDigestForDate(at, date);
            if (raw.isPresent()) {
                var digest = outlookParser.toDomain(raw.get());
                cache(userId, digest, date);
                return Optional.of(digest);
            }
        }

        return Optional.empty();
    }

    private void cache(String userId, USPSDigest d) {
        cache(userId, d, null);
    }

    private void cache(String userId, USPSDigest d, LocalDate requestedDate) {
        try {
            var c = new USPSDigestCache();
            c.setUserId(userId);
            Instant digestInstant;
            if (requestedDate != null) {
                digestInstant = requestedDate.atStartOfDay(ZoneOffset.UTC).toInstant();
            } else if (d.digestDate() != null) {
                digestInstant = d.digestDate().toInstant();
            } else {
                digestInstant = Instant.now();
            }
            c.setDigestDate(digestInstant);
            c.setPayloadJson(om.writeValueAsString(d));
            c.setExpiresAt(Instant.now().plus(Duration.ofHours(6)));
            cacheRepo.save(c);
        } catch (Exception ignored) {}
    }

    public void clearCacheForUser(String userId) {
        // Delete all cache entries for the user by setting their expiration to the past
        var userCacheEntries = cacheRepo.findAll()
                .stream()
                .filter(cache -> userId.equals(cache.getUserId()))
                .toList();

        for (var entry : userCacheEntries) {
            entry.setExpiresAt(Instant.now().minus(Duration.ofHours(1))); // Expire 1 hour ago
            cacheRepo.save(entry);
        }
    }

    private String decrypt(String s) {
        return tokenCryptor.decrypt(s);
    }

    private USPSDigest mockDigest() {
        var now = OffsetDateTime.now(ZoneOffset.UTC);
        var pkg = new PackageItem("9400100000000000000000", "USPS Package", now.plusDays(1),
                ActionLinks.defaults("https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=9400100000000000000000"));
        var mp  = new MailPiece("m-1","ACME Bank","Monthly statement",
                "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAnIGhlaWdodD0nMjAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHJlY3Qgd2lkdGg9JzQwJyBoZWlnaHQ9JzIwJyBmaWxsPSIjZGRkIi8+PC9zdmc+",
                now, ActionLinks.defaults(null));
        return new USPSDigest(now, List.of(mp), List.of(pkg));
    }
}
