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
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;

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
        responseWriter = new StringWriter();

        when(response.getWriter()).thenReturn(new PrintWriter(responseWriter));
        SecurityContextHolder.setContext(securityContext);
    }

    @Test
    public void testLoginRateLimit() throws ServletException, IOException {
        // Mock request for login endpoint
        when(request.getRequestURI()).thenReturn("/v1/api/auth/login");
        when(request.getRemoteAddr()).thenReturn("127.0.0.1");
        when(securityContext.getAuthentication()).thenReturn(null);

        // Simulate 5 requests (should pass)
        for (int i = 0; i < 5; i++) {
            reset(filterChain);
            rateLimitingFilter.doFilter(request, response, filterChain);
            verify(filterChain, times(1)).doFilter(request, response);
            verify(response, never()).setStatus(429);
        }

        // 6th request should be rate limited
        reset(filterChain);
        rateLimitingFilter.doFilter(request, response, filterChain);
        verify(filterChain, never()).doFilter(request, response);
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
        verify(response).addHeader("X-RateLimit-Reset", "60");
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
}