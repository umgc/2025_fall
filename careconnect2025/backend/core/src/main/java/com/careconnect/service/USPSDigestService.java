package com.careconnect.service;

import com.careconnect.model.*;
import com.careconnect.repository.EmailCredentialRepo;
import com.careconnect.repository.USPSDigestCacheRepo;
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

        // 4) mock fallback so you can test UI today
        var mock = mockDigest();
        cache(userId, mock);
        return Optional.of(mock);
    }

    private void cache(String userId, USPSDigest d) {
        try {
            var c = new USPSDigestCache();
            c.setUserId(userId);
            c.setDigestDate(d.digestDate() != null ? d.digestDate().toInstant() : Instant.now());
            c.setPayloadJson(om.writeValueAsString(d));
            c.setExpiresAt(Instant.now().plus(Duration.ofHours(6)));
            cacheRepo.save(c);
        } catch (Exception ignored) {}
    }

    private String decrypt(String s) { return s; } // TODO: plug KMS/JCE

    private USPSDigest mockDigest() {
        var now = OffsetDateTime.now(ZoneOffset.UTC);
        var pkg = new PackageItem("9400100000000000000000", now.plusDays(1).toString(),
                ActionLinks.defaults("https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=9400100000000000000000"));
        var mp  = new MailPiece("m-1","ACME Bank","Monthly statement",
                "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAnIGhlaWdodD0nMjAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHJlY3Qgd2lkdGg9JzQwJyBoZWlnaHQ9JzIwJyBmaWxsPSIjZGRkIi8+PC9zdmc+",
                now.toString(), ActionLinks.defaults(null));
        return new USPSDigest(now, List.of(mp), List.of(pkg));
    }
}
