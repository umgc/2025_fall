package com.careconnect.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Collection;
import java.util.List;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.charset.StandardCharsets;

import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletInputStream;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

public class RateLimitingFilterUnitTest {

    @Mock
    private HttpServletRequest request;

    @Mock
    private HttpServletResponse response;

    @Mock
    private FilterChain filterChain;

    @Mock
    private Authentication authentication;

    @Mock
    private SecurityContext securityContext;

    private RateLimitingFilter rateLimitingFilter;
    private StringWriter responseWriter;

    @BeforeEach
    void setUp() throws IOException {
        MockitoAnnotations.openMocks(this);
        rateLimitingFilter = new RateLimitingFilter();
        rateLimitingFilter.setLoginResetWindowSeconds(30); // Set explicit value for testing
        rateLimitingFilter.clearAllRateLimits(); // Clear cache before each test
        responseWriter = new StringWriter();

        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        SecurityContextHolder.setContext(securityContext);
    }

    @Test
    public void testLoginRateLimit() throws ServletException, IOException {
        // Mock request for login endpoint - but this test uses IP-based limiting
        // since it doesn't provide POST method or JSON body
        when(request.getRequestURI()).thenReturn("/v1/api/auth/login");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");
        when(securityContext.getAuthentication()).thenReturn(null);

        // Simulate 5 requests (should pass)
        for (int i = 0; i < 5; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(any(), any());
            verify(response, never()).setStatus(429);
        }

        // 6th request should be rate limited
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(any(), any());
        verify(response).setStatus(429);

        String responseContent = responseWriter.toString();
        assertTrue(responseContent.contains("Rate limit exceeded"));
        assertTrue(responseContent.contains("retryAfter"));
    }

    @Test
    public void testAiChatRateLimit() throws ServletException, IOException {
        // Mock request for AI chat endpoint
        when(request.getRequestURI()).thenReturn("/v1/api/ai-chat/message");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");
        when(securityContext.getAuthentication()).thenReturn(null);

        // Simulate 10 requests (should pass)
        for (int i = 0; i < 10; i++) {
            reset(filterChain);
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // 11th request should be rate limited
        reset(filterChain);
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
        verify(response).setStatus(429);
    }

    @Test
    public void testAuthenticatedUser() throws ServletException, IOException {
        // Mock authenticated user
        when(request.getRequestURI()).thenReturn("/v1/api/auth/login");
        when(authentication.isAuthenticated()).thenReturn(true);
        when(authentication.getName()).thenReturn("testuser");
        when(authentication.getPrincipal()).thenReturn("testuser");
        when(securityContext.getAuthentication()).thenReturn(authentication);

        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain).doFilter(request, response);
        verify(response, never()).setStatus(429);
    }

    @Test
    public void testSkipRateLimitingForHealthCheck() throws ServletException, IOException {
        // Mock health check endpoint
        when(request.getRequestURI()).thenReturn("/health");

        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain).doFilter(request, response);
        verify(response, never()).setStatus(429);
    }

    @Test
    public void testRateLimitHeaders() throws ServletException, IOException {
        when(request.getRequestURI()).thenReturn("/v1/api/auth/login");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");
        when(securityContext.getAuthentication()).thenReturn(null);

        rateLimitingFilter.doFilter(request, response, filterChain);

        verify(response).addHeader("X-RateLimit-Limit", "5");
        verify(response).addHeader("X-RateLimit-Remaining", "4");
        verify(response).addHeader("X-RateLimit-Reset", "30"); // Login endpoint uses 30 seconds
    }

    @Test
    public void testExtendedRateLimit() throws ServletException, IOException {
        when(request.getRequestURI()).thenReturn("/v1/api/ai-chat/test");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");
        when(securityContext.getAuthentication()).thenReturn(null);

        rateLimitingFilter.doFilter(request, response, filterChain);

        verify(response).addHeader("X-RateLimit-Extended-Limit", "100");
        verify(response).addHeader("X-RateLimit-Extended-Remaining", "99");
        verify(response).addHeader("X-RateLimit-Extended-Window", "15 minutes");
    }

    @Test
    public void testSeparateRateLimitsForPatientAndCaregiver() throws ServletException, IOException {
        // Test that patients and caregivers have separate rate limiting buckets
        when(request.getRequestURI()).thenReturn("/v1/api/ai-chat/message");

        // Create patient authentication
        Authentication patientAuth = mock(Authentication.class);
        when(patientAuth.isAuthenticated()).thenReturn(true);
        when(patientAuth.getName()).thenReturn("patient@test.com");
        when(patientAuth.getPrincipal()).thenReturn("patient@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_PATIENT")))
            .when(patientAuth).getAuthorities();

        // Create caregiver authentication
        Authentication caregiverAuth = mock(Authentication.class);
        when(caregiverAuth.isAuthenticated()).thenReturn(true);
        when(caregiverAuth.getName()).thenReturn("caregiver@test.com");
        when(caregiverAuth.getPrincipal()).thenReturn("caregiver@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_CAREGIVER")))
            .when(caregiverAuth).getAuthorities();

        // Make 10 requests as patient (should all pass for AI chat endpoint limit)
        when(securityContext.getAuthentication()).thenReturn(patientAuth);
        for (int i = 0; i < 10; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // Make 10 requests as caregiver (should also all pass since they have separate buckets)
        when(securityContext.getAuthentication()).thenReturn(caregiverAuth);
        for (int i = 0; i < 10; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // 11th request as patient should be rate limited
        when(securityContext.getAuthentication()).thenReturn(patientAuth);
        reset(filterChain, response);
        when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
        verify(response).setStatus(429);

        // 11th request as caregiver should also be rate limited (separate bucket)
        when(securityContext.getAuthentication()).thenReturn(caregiverAuth);
        reset(filterChain, response);
        when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
        verify(response).setStatus(429);
    }

    @Test
    public void testConfigurableLoginResetWindow() throws ServletException, IOException {
        // Mock request for login endpoint
        when(request.getRequestURI()).thenReturn("/v1/api/auth/login");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");
        when(securityContext.getAuthentication()).thenReturn(null);

        // Verify that the response message includes the configured reset window
        // Simulate 5 requests (should pass)
        for (int i = 0; i < 5; i++) {
            reset(filterChain);
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // 6th request should be rate limited with custom message
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
        verify(response).setStatus(429);

        String responseContent = responseWriter.toString();
        assertTrue(responseContent.contains("Rate limit exceeded"));
        // Should show the configured reset window (default 30 seconds for development)
        assertTrue(responseContent.contains("30"));
    }

    @Test
    public void testSeparateRateLimitsForLoginByRole() throws ServletException, IOException {
        // Test that login attempts with different roles have separate rate limiting
        when(request.getRequestURI()).thenReturn("/v1/api/auth/login");
        when(request.getMethod()).thenReturn("POST");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");
        when(securityContext.getAuthentication()).thenReturn(null);

        // Make 5 login attempts as PATIENT (should all pass)
        String patientLoginJson = "{\"email\":\"patient@test.com\",\"password\":\"password\",\"role\":\"PATIENT\"}";
        for (int i = 0; i < 5; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            mockRequestWithBody(patientLoginJson);
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(any(), any());
            verify(response, never()).setStatus(429);
        }

        // Make 5 login attempts as CAREGIVER (should also all pass since separate bucket)
        String caregiverLoginJson = "{\"email\":\"caregiver@test.com\",\"password\":\"password\",\"role\":\"CAREGIVER\"}";
        for (int i = 0; i < 5; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            mockRequestWithBody(caregiverLoginJson);
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(any(), any());
            verify(response, never()).setStatus(429);
        }

        // 6th attempt as PATIENT should be rate limited
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        mockRequestWithBody(patientLoginJson);
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(any(), any());
        verify(response).setStatus(429);

        String responseContent = responseWriter.toString();
        assertTrue(responseContent.contains("Rate limit exceeded"));

        // 6th attempt as CAREGIVER should also be rate limited (separate bucket)
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        mockRequestWithBody(caregiverLoginJson);
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(any(), any());
        verify(response).setStatus(429);
    }

    private void mockRequestWithBody(String json) throws IOException {
        byte[] bodyBytes = json.getBytes(StandardCharsets.UTF_8);
        ServletInputStream inputStream = new ServletInputStream() {
            private final ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(bodyBytes);

            @Override
            public int read() throws IOException {
                return byteArrayInputStream.read();
            }

            @Override
            public boolean isFinished() {
                return byteArrayInputStream.available() == 0;
            }

            @Override
            public boolean isReady() {
                return true;
            }

            @Override
            public void setReadListener(ReadListener readListener) {
                throw new UnsupportedOperationException();
            }
        };

        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream, StandardCharsets.UTF_8));
        when(request.getInputStream()).thenReturn(inputStream);
        when(request.getReader()).thenReturn(reader);
    }

    @Test
    public void testOptionsRequestsSkipRateLimiting() throws ServletException, IOException {
        // Test that OPTIONS (CORS preflight) requests are not rate limited
        when(request.getRequestURI()).thenReturn("/v1/api/auth/login");
        when(request.getMethod()).thenReturn("OPTIONS");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");

        // Make many OPTIONS requests - none should be rate limited
        for (int i = 0; i < 20; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(any(), any());
            verify(response, never()).setStatus(429);
        }
    }

    @Test
    public void testPatientProfileRateLimiting() throws ServletException, IOException {
        // Test patient profile endpoint rate limiting
        when(request.getRequestURI()).thenReturn("/v1/api/patients/me");
        when(request.getMethod()).thenReturn("GET");
        
        // Create patient authentication
        Authentication patientAuth = mock(Authentication.class);
        when(patientAuth.isAuthenticated()).thenReturn(true);
        when(patientAuth.getName()).thenReturn("patient@test.com");
        when(patientAuth.getPrincipal()).thenReturn("patient@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_PATIENT")))
            .when(patientAuth).getAuthorities();
        when(securityContext.getAuthentication()).thenReturn(patientAuth);

        // Make 30 requests (should pass for patient profile GET limit)
        for (int i = 0; i < 30; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // 31st request should be rate limited
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
        verify(response).setStatus(429);
    }

    @Test
    public void testPatientProfileWriteOperationRateLimiting() throws ServletException, IOException {
        // Test patient profile write operation rate limiting (stricter limits)
        when(request.getRequestURI()).thenReturn("/v1/api/patients/me");
        when(request.getMethod()).thenReturn("PUT");
        
        // Create patient authentication
        Authentication patientAuth = mock(Authentication.class);
        when(patientAuth.isAuthenticated()).thenReturn(true);
        when(patientAuth.getName()).thenReturn("patient@test.com");
        when(patientAuth.getPrincipal()).thenReturn("patient@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_PATIENT")))
            .when(patientAuth).getAuthorities();
        when(securityContext.getAuthentication()).thenReturn(patientAuth);

        // Make 10 requests (should pass for patient profile PUT limit)
        for (int i = 0; i < 10; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // 11th request should be rate limited
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
        verify(response).setStatus(429);
    }

    @Test
    public void testCaregiverProfileRateLimiting() throws ServletException, IOException {
        // Test caregiver profile endpoint rate limiting
        when(request.getRequestURI()).thenReturn("/v1/api/caregivers/123");
        when(request.getMethod()).thenReturn("GET");
        
        // Create caregiver authentication
        Authentication caregiverAuth = mock(Authentication.class);
        when(caregiverAuth.isAuthenticated()).thenReturn(true);
        when(caregiverAuth.getName()).thenReturn("caregiver@test.com");
        when(caregiverAuth.getPrincipal()).thenReturn("caregiver@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_CAREGIVER")))
            .when(caregiverAuth).getAuthorities();
        when(securityContext.getAuthentication()).thenReturn(caregiverAuth);

        // Make 50 requests (should pass for caregiver profile GET limit)
        for (int i = 0; i < 50; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(any(), any());
            verify(response, never()).setStatus(429);
        }

        // 51st request should be rate limited
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(any(), any());
        verify(response).setStatus(429);
    }

    @Test
    public void testCaregiverProfileWriteOperationRateLimiting() throws ServletException, IOException {
        // Test caregiver profile write operation rate limiting
        when(request.getRequestURI()).thenReturn("/v1/api/caregivers/123");
        when(request.getMethod()).thenReturn("PUT");
        
        // Create caregiver authentication
        Authentication caregiverAuth = mock(Authentication.class);
        when(caregiverAuth.isAuthenticated()).thenReturn(true);
        when(caregiverAuth.getName()).thenReturn("caregiver@test.com");
        when(caregiverAuth.getPrincipal()).thenReturn("caregiver@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_CAREGIVER")))
            .when(caregiverAuth).getAuthorities();
        when(securityContext.getAuthentication()).thenReturn(caregiverAuth);

        // Make 15 requests (should pass for caregiver profile PUT limit)
        for (int i = 0; i < 15; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // 16th request should be rate limited
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
        verify(response).setStatus(429);
    }

    @Test
    public void testFamilyMemberProfileRateLimiting() throws ServletException, IOException {
        // Test family member profile endpoint rate limiting
        when(request.getRequestURI()).thenReturn("/v1/api/family-members/patients");
        when(request.getMethod()).thenReturn("GET");
        
        // Create family member authentication
        Authentication familyMemberAuth = mock(Authentication.class);
        when(familyMemberAuth.isAuthenticated()).thenReturn(true);
        when(familyMemberAuth.getName()).thenReturn("family@test.com");
        when(familyMemberAuth.getPrincipal()).thenReturn("family@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_FAMILY_MEMBER")))
            .when(familyMemberAuth).getAuthorities();
        when(securityContext.getAuthentication()).thenReturn(familyMemberAuth);

        // Make 30 requests (should pass for family member profile GET limit)
        for (int i = 0; i < 30; i++) {
            reset(filterChain, response);
            when(response.getWriter()).thenReturn(new PrintWriter(new StringWriter()));
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(any(), any());
            verify(response, never()).setStatus(429);
        }

        // 31st request should be rate limited
        reset(filterChain, response);
        responseWriter = new StringWriter();
        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(any(), any());
        verify(response).setStatus(429);
    }

    @Test
    public void testRoleSpecificRateLimitHeaders() throws ServletException, IOException {
        // Test that rate limit headers include role information
        when(request.getRequestURI()).thenReturn("/v1/api/patients/me");
        when(request.getMethod()).thenReturn("GET");
        
        // Create patient authentication
        Authentication patientAuth = mock(Authentication.class);
        when(patientAuth.isAuthenticated()).thenReturn(true);
        when(patientAuth.getName()).thenReturn("patient@test.com");
        when(patientAuth.getPrincipal()).thenReturn("patient@test.com");
        doReturn(List.of(new SimpleGrantedAuthority("ROLE_PATIENT")))
            .when(patientAuth).getAuthorities();
        when(securityContext.getAuthentication()).thenReturn(patientAuth);

        rateLimitingFilter.doFilter(request, response, filterChain);

        verify(response).addHeader("X-RateLimit-Limit", "30");
        verify(response).addHeader("X-RateLimit-Remaining", "29");
        verify(response).addHeader("X-RateLimit-Role", "PATIENT");
    }
}