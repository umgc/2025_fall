package com.careconnect.service;

import com.careconnect.dto.GmailDigestPayload;
import com.careconnect.model.EmailCredential;
import com.careconnect.model.UspsDigest;
import com.careconnect.model.UspsDigestCache;
import com.careconnect.repository.EmailCredentialRepository;
import com.careconnect.repository.UspsDigestCacheRepo;
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

class UspsDigestServiceTest {

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
        UspsDigest digest = UspsDigest.builder()
                .digestDate(OffsetDateTime.now(ZoneOffset.UTC))
                .mailPieces(List.of())
                .packages(List.of())
                .build();
        gmailParser.digest = digest;

        UspsDigestService service = new UspsDigestService(
                emailRepo,
                cacheStub.asRepo(),
                gmailClient,
                gmailParser,
                new OutlookClient(),
                new OutlookParser(),
                cryptor
        );

        Optional<UspsDigest> result = service.latestForUser("user-1");

        assertTrue(result.isPresent());
        assertEquals(digest, result.get());
        assertNotNull(cacheStub.saved, "Digest should be cached");
        assertEquals("user-1", cacheStub.saved.getUserId());
        assertNotNull(cacheStub.saved.getPayloadJson());
    }

    @Test
    void returnsCachedDigestWhenAvailable() throws Exception {
        var cacheStub = new CacheRepoStub();

        var cached = new UspsDigestCache();
        cached.setUserId("user-2");
        cached.setDigestDate(Instant.now());
        cached.setExpiresAt(Instant.now().plusSeconds(3600));
        cached.setPayloadJson("{\"digestDate\":null,\"mailPieces\":[],\"packages\":[]}");
        cacheStub.nextLookup = Optional.of(cached);

        UspsDigestService service = new UspsDigestService(
                emailCredentialRepository(Optional.empty()),
                cacheStub.asRepo(),
                new StubGmailClient(),
                new StubGmailParser(),
                new OutlookClient(),
                new OutlookParser(),
                cryptor
        );

        Optional<UspsDigest> result = service.latestForUser("user-2");

        assertTrue(result.isPresent());
        assertNull(result.get().getDigestDate());
        assertNull(cacheStub.saved, "Cached value should be reused without overwriting");
    }

    private EmailCredentialRepository emailCredentialRepository(Optional<EmailCredential> credential) {
        InvocationHandler handler = new InvocationHandler() {
            @Override
            public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                if (method.getDeclaringClass() == Object.class) {
                    return switch (method.getName()) {
                        case "toString" -> "EmailCredentialRepositoryStub";
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
        return (EmailCredentialRepository) Proxy.newProxyInstance(
                UspsDigestServiceTest.class.getClassLoader(),
                new Class[]{EmailCredentialRepository.class},
                handler
        );
    }

    private static class CacheRepoStub {
        Optional<UspsDigestCache> nextLookup = Optional.empty();
        UspsDigestCache saved;

        UspsDigestCacheRepo asRepo() {
            InvocationHandler handler = new InvocationHandler() {
                @Override
                public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                    if (method.getDeclaringClass() == Object.class) {
                        return switch (method.getName()) {
                            case "toString" -> "UspsDigestCacheRepoStub";
                            case "hashCode" -> System.identityHashCode(proxy);
                            case "equals" -> proxy == args[0];
                            default -> method.invoke(this, args);
                        };
                    }
                    return switch (method.getName()) {
                        case "findFirstByUserIdAndExpiresAtAfterOrderByDigestDateDesc" -> nextLookup;
                        case "save" -> {
                            saved = (UspsDigestCache) args[0];
                            yield saved;
                        }
                        default -> throw new UnsupportedOperationException("Unsupported: " + method.getName());
                    };
                }
            };
            return (UspsDigestCacheRepo) Proxy.newProxyInstance(
                    UspsDigestServiceTest.class.getClassLoader(),
                    new Class[]{UspsDigestCacheRepo.class},
                    handler
            );
        }
    }

    private static class StubGmailClient extends GmailClient {
        Optional<GmailDigestPayload> payload = Optional.empty();

        @Override
        public Optional<GmailDigestPayload> fetchLatestDigest(String accessToken) {
            return payload;
        }
    }

    private static class StubGmailParser extends GmailParser {
        UspsDigest digest;

        @Override
        public UspsDigest toDomain(GmailDigestPayload payload) {
            return digest;
        }
    }
}
