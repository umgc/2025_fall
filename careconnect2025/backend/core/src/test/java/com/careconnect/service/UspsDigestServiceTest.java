package com.careconnect.service;

import com.careconnect.dto.GmailDigestPayload;
import com.careconnect.model.EmailCredential;
import com.careconnect.model.USPSDigest;
import com.careconnect.model.USPSDigestCache;
import com.careconnect.repository.EmailCredentialRepo;
import com.careconnect.repository.USPSDigestCacheRepo;
import com.careconnect.security.TokenCryptor;
import org.junit.jupiter.api.Test;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;

class USPSDigestServiceTest {

    private final TokenCryptor cryptor = new TokenCryptor("unit-test-secret-32-bytes-long!!!");

    @Test
    void returnsGmailDigestAndCachesResult() {
        var cacheStub = new CacheRepoStub();
        cacheStub.nextLookup = Optional.empty();

        var credential = new EmailCredential();
        credential.setUserId("user-1");
        credential.setProvider(EmailCredential.Provider.GMAIL);
        credential.setAccessTokenEnc(cryptor.encrypt("access-token"));
        var emailRepo = emailCredentialRepository(Optional.of(credential));

        var gmailClient = new StubGmailClient();
        GmailDigestPayload payload = new GmailDigestPayload("<html></html>", Map.of(), OffsetDateTime.now());
        gmailClient.payload = Optional.of(payload);

        var gmailParser = new StubGmailParser();
        USPSDigest digest = new USPSDigest(
                OffsetDateTime.now(ZoneOffset.UTC),
                List.of(),
                List.of());
        gmailParser.digest = digest;

        USPSDigestService service = new USPSDigestService(
                emailRepo,
                cacheStub.asRepo(),
                gmailClient,
                new OutlookClient(),
                gmailParser,
                new OutlookParser(),
                new TokenCryptor("test-secret-key")
        );

        Optional<USPSDigest> result = service.latestForUser("user-1");

        assertTrue(result.isPresent());
        assertEquals(digest, result.get());
        assertNotNull(cacheStub.saved, "Digest should be cached");
        assertEquals("user-1", cacheStub.saved.getUserId());
        assertNotNull(cacheStub.saved.getPayloadJson());
    }

    @Test
    void returnsCachedDigestWhenAvailable() throws Exception {
        var cacheStub = new CacheRepoStub();

        var cached = new USPSDigestCache();
        cached.setUserId("user-2");
        cached.setDigestDate(Instant.now());
        cached.setExpiresAt(Instant.now().plusSeconds(3600));
        cached.setPayloadJson("{\"digestDate\":null,\"mailPieces\":[],\"packages\":[]}");
        cacheStub.nextLookup = Optional.of(cached);

        USPSDigestService service = new USPSDigestService(
                emailCredentialRepository(Optional.empty()),
                cacheStub.asRepo(),
                new StubGmailClient(),
                new OutlookClient(),
                new StubGmailParser(),
                new OutlookParser(),
                new TokenCryptor("test-secret-key")
        );

        Optional<USPSDigest> result = service.latestForUser("user-2");

        assertTrue(result.isPresent());
        assertNull(result.get().digestDate());
        assertNull(cacheStub.saved, "Cached value should be reused without overwriting");
    }

    private EmailCredentialRepo emailCredentialRepository(Optional<EmailCredential> credential) {
        InvocationHandler handler = new InvocationHandler() {
            @Override
            public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                if (method.getDeclaringClass() == Object.class) {
                    return switch (method.getName()) {
                        case "toString" -> "EmailCredentialRepoStub";
                        case "hashCode" -> System.identityHashCode(proxy);
                        case "equals" -> proxy == args[0];
                        default -> method.invoke(this, args);
                    };
                }
                return switch (method.getName()) {
                    case "findFirstByUserIdAndProvider", "findFirstByUserIdAndProviderOrderByIdDesc" -> credential;
                    default -> throw new UnsupportedOperationException("Unsupported: " + method.getName());
                };
            }
        };
        return (EmailCredentialRepo) Proxy.newProxyInstance(
                USPSDigestServiceTest.class.getClassLoader(),
                new Class[]{EmailCredentialRepo.class},
                handler
        );
    }

    private static class CacheRepoStub {
        Optional<USPSDigestCache> nextLookup = Optional.empty();
        USPSDigestCache saved;

        USPSDigestCacheRepo asRepo() {
            InvocationHandler handler = new InvocationHandler() {
                @Override
                public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                    if (method.getDeclaringClass() == Object.class) {
                        return switch (method.getName()) {
                            case "toString" -> "USPSDigestCacheRepoStub";
                            case "hashCode" -> System.identityHashCode(proxy);
                            case "equals" -> proxy == args[0];
                            default -> method.invoke(this, args);
                        };
                    }
                    return switch (method.getName()) {
                        case "findFirstByUserIdAndExpiresAtAfterOrderByDigestDateDesc" -> nextLookup;
                        case "save" -> {
                            saved = (USPSDigestCache) args[0];
                            yield saved;
                        }
                        default -> throw new UnsupportedOperationException("Unsupported: " + method.getName());
                    };
                }
            };
            return (USPSDigestCacheRepo) Proxy.newProxyInstance(
                    USPSDigestServiceTest.class.getClassLoader(),
                    new Class[]{USPSDigestCacheRepo.class},
                    handler
            );
        }
    }

    private GoogleOAuthService googleOAuthServiceStub() {
        return new GoogleOAuthService(null, null, cryptor) {
            @Override
            public EmailCredential ensureFreshToken(EmailCredential current) {
                return current;
            }
        };
    }

    private static class StubGmailClient extends GmailClient {
        Optional<GmailDigestPayload> payload = Optional.empty();

        @Override
        public Optional<GmailDigestPayload> fetchLatestDigest(String accessToken) {
            return payload;
        }
    }

    private static class StubGmailParser extends GmailParser {
        USPSDigest digest;

        @Override
        public USPSDigest toDomain(GmailDigestPayload payload) {
            return digest;
        }
    }
}
