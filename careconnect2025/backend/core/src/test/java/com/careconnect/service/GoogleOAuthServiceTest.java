package com.careconnect.service;

import com.careconnect.model.EmailCredential;
import com.careconnect.repository.EmailCredentialRepository;
import com.careconnect.security.TokenCryptor;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestTemplate;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.*;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class GoogleOAuthServiceTest {

    private TokenCryptor tokenCryptor;
    private GoogleOAuthService service;
    private AtomicReference<EmailCredential> savedRef;
    private MockRestServiceServer server;

    @BeforeEach
    void setUp() {
        tokenCryptor = new TokenCryptor("unit-test-secret-32-bytes-long!!!");
        savedRef = new AtomicReference<>();

        RestTemplate rt = new RestTemplate();
        server = MockRestServiceServer.createServer(rt);

        service = new GoogleOAuthService(rt, createRepositoryStub(), tokenCryptor);
        service.clientId = "test-client";
        service.clientSecret = "test-secret";
        service.redirectUri = "http://localhost/oauth/callback";
    }

    @Test
    void ensureFreshTokenReturnsCurrentWhenStillValid() {
        EmailCredential credential = new EmailCredential();
        credential.setAccessTokenEnc(tokenCryptor.encrypt("existing"));
        credential.setRefreshTokenEnc(tokenCryptor.encrypt("refresh-123"));
        credential.setExpiresAt(Instant.now().plusSeconds(600));

        EmailCredential result = service.ensureFreshToken(credential);

        assertSame(credential, result);
        assertNull(savedRef.get(), "Repository save should not be invoked");

        // No HTTP expectations set, verify that no unexpected calls were made
        server.verify();
    }

    @Test
    void ensureFreshTokenRefreshesWhenExpired() {
        EmailCredential credential = new EmailCredential();
        credential.setAccessTokenEnc(tokenCryptor.encrypt("stale"));
        credential.setRefreshTokenEnc(tokenCryptor.encrypt("refresh-321"));
        credential.setExpiresAt(Instant.now().minusSeconds(5));

        String json = """
                {
                  "access_token": "new-access-token",
                  "expires_in": 3600
                }
                """;

        server.expect(requestTo("https://oauth2.googleapis.com/token"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(header("Content-Type", MediaType.APPLICATION_FORM_URLENCODED_VALUE))
                .andExpect(content().contentType(MediaType.APPLICATION_FORM_URLENCODED))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("grant_type=refresh_token")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("client_id=test-client")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("client_secret=test-secret")))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("refresh_token=refresh-321")))
                .andRespond(withSuccess(json, MediaType.APPLICATION_JSON));

        EmailCredential result = service.ensureFreshToken(credential);

        assertSame(credential, result);
        EmailCredential persisted = savedRef.get();
        assertNotNull(persisted, "Repository save should capture entity");
        assertSame(credential, persisted, "Service should update the same credential instance");
        assertEquals("new-access-token", tokenCryptor.decrypt(persisted.getAccessTokenEnc()));
        assertTrue(persisted.getExpiresAt().isAfter(Instant.now()));

        server.verify();
    }

    private EmailCredentialRepository createRepositoryStub() {
        InvocationHandler handler = new InvocationHandler() {
            @Override
            public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
                String name = method.getName();
                if (method.getDeclaringClass() == Object.class) {
                    return switch (name) {
                        case "toString" -> "EmailCredentialRepositoryStub";
                        case "hashCode" -> System.identityHashCode(proxy);
                        case "equals" -> proxy == args[0];
                        default -> method.invoke(this, args);
                    };
                }
                switch (name) {
                    case "save" -> {
                        EmailCredential entity = (EmailCredential) args[0];
                        savedRef.set(entity);
                        return entity;
                    }
                    case "findFirstByUserIdAndProvider", "findFirstByUserIdAndProviderOrderByIdDesc" -> {
                        return Optional.empty();
                    }
                    default -> throw new UnsupportedOperationException("Method " + name + " not supported in stub");
                }
            }
        };
        return (EmailCredentialRepository) Proxy.newProxyInstance(
                GoogleOAuthServiceTest.class.getClassLoader(),
                new Class[]{EmailCredentialRepository.class},
                handler
        );
    }
}
