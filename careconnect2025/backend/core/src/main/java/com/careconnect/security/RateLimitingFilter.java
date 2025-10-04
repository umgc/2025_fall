package com.careconnect.security;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.annotation.Order;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Component;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequestWrapper;

@Component
@Order(0)
public class RateLimitingFilter implements Filter {

    private static final Logger logger = LoggerFactory.getLogger(RateLimitingFilter.class);
    private static final int SC_TOO_MANY_REQUESTS = 429;

    @Value("${careconnect.rate-limit.login.reset-window-seconds:30}")
    private long loginResetWindowSeconds;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // Setter for testing purposes
    public void setLoginResetWindowSeconds(long loginResetWindowSeconds) {
        this.loginResetWindowSeconds = loginResetWindowSeconds;
    }

    private static final Map<String, Integer> RATE_LIMITS = Map.of(
            "/v1/api/auth/login", 5, // limit login attempts to 5 per minute
            "/v1/api/ai-chat/", 10, // limit AI chat requests to 10 per minute
            "/v1/api/notetaker/ai/", 5, // limit note taker AI requests to 5 per minute
            "default", 60 // default limit for all other endpoints: 60 requests per minute
    );

    private static final Map<String, ExtendedLimitConfig> EXTENDED_LIMITS = Map.of(
            "/v1/api/ai-chat/", new ExtendedLimitConfig(100, 15),
            "/v1/api/notetaker/ai/", new ExtendedLimitConfig(50, 15)
    );

    private final Cache<String, RateLimitBucket> perMinuteCache = Caffeine.newBuilder()
            .expireAfterWrite(35, TimeUnit.MINUTES) // Extended to handle 30-minute login window + buffer
            .maximumSize(10000)
            .build();

    private final Cache<String, RateLimitBucket> extendedCache = Caffeine.newBuilder()
            .expireAfterWrite(20, TimeUnit.MINUTES)
            .maximumSize(10000)
            .build();

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        if (shouldSkipRateLimiting(httpRequest)) {
            chain.doFilter(request, response);
            return;
        }

        // For login requests, wrap the request to allow reading the body multiple times
        HttpServletRequest processableRequest = httpRequest;
        if (httpRequest.getRequestURI().startsWith("/v1/api/auth/login") &&
            "POST".equalsIgnoreCase(httpRequest.getMethod())) {
            try {
                processableRequest = new CachedBodyHttpServletRequest(httpRequest);
            } catch (IOException e) {
                logger.warn("Failed to cache request body for rate limiting, falling back to IP-based: {}", e.getMessage());
            }
        }

        String userId = getUserIdentifier(processableRequest);
        String endpoint = processableRequest.getRequestURI();
        String normalizedEndpoint = normalizeEndpoint(endpoint);


        if (!checkPerMinuteLimit(userId, normalizedEndpoint, httpResponse)) {
            return;
        }

        if (!checkExtendedLimit(userId, normalizedEndpoint, httpResponse)) {
            return;
        }

        addRateLimitHeaders(httpResponse, userId, normalizedEndpoint);
        chain.doFilter(processableRequest, response);
    }

    private boolean checkPerMinuteLimit(String userId, String endpoint, HttpServletResponse response)
            throws IOException {

        int limit = getRateLimitForEndpoint(endpoint);
        long windowSeconds = getResetWindowForEndpoint(endpoint);
        String key = buildCacheKey(userId, endpoint);
        RateLimitBucket bucket = perMinuteCache.get(key, k -> new RateLimitBucket(limit, windowSeconds));

        if (!bucket.tryConsume()) {
            logger.warn("Rate limit exceeded for user: {} on endpoint: {} (window: {} seconds)", userId, endpoint, windowSeconds);
            sendRateLimitResponse(response,
                String.format("Rate limit exceeded. Please try again in %d seconds.", windowSeconds));
            return false;
        }

        return true;
    }

    private boolean checkExtendedLimit(String userId, String endpoint, HttpServletResponse response)
            throws IOException {

        ExtendedLimitConfig extendedConfig = getExtendedLimitForEndpoint(endpoint);
        if (extendedConfig == null) {
            return true;
        }

        String key = buildCacheKey(userId, endpoint + ":extended");
        RateLimitBucket bucket = extendedCache.get(key,
                k -> new RateLimitBucket(extendedConfig.getLimit(), extendedConfig.getWindowMinutes() * 60));

        if (!bucket.tryConsume()) {
            logger.warn("Extended rate limit exceeded for user: {} on endpoint: {} ({} requests per {} minutes)",
                    userId, endpoint, extendedConfig.getLimit(), extendedConfig.getWindowMinutes());
            sendRateLimitResponse(response,
                    String.format("Rate limit exceeded. Maximum %d requests per %d minutes.",
                            extendedConfig.getLimit(), extendedConfig.getWindowMinutes()));
            return false;
        }

        return true;
    }

    private void addRateLimitHeaders(HttpServletResponse response, String userId, String endpoint) {
        try {
            int limit = getRateLimitForEndpoint(endpoint);
            long windowSeconds = getResetWindowForEndpoint(endpoint);
            String key = buildCacheKey(userId, endpoint);
            RateLimitBucket bucket = perMinuteCache.getIfPresent(key);

            if (bucket != null) {
                int remaining = Math.max(0, limit - bucket.getCount());
                response.addHeader("X-RateLimit-Limit", String.valueOf(limit));
                response.addHeader("X-RateLimit-Remaining", String.valueOf(remaining));
                response.addHeader("X-RateLimit-Reset", String.valueOf(windowSeconds));
            }

            ExtendedLimitConfig extendedConfig = getExtendedLimitForEndpoint(endpoint);
            if (extendedConfig != null) {
                String extendedKey = buildCacheKey(userId, endpoint + ":extended");
                RateLimitBucket extendedBucket = extendedCache.getIfPresent(extendedKey);

                if (extendedBucket != null) {
                    int extendedRemaining = Math.max(0, extendedConfig.getLimit() - extendedBucket.getCount());
                    response.addHeader("X-RateLimit-Extended-Limit", String.valueOf(extendedConfig.getLimit()));
                    response.addHeader("X-RateLimit-Extended-Remaining", String.valueOf(extendedRemaining));
                    response.addHeader("X-RateLimit-Extended-Window", extendedConfig.getWindowMinutes() + " minutes");
                }
            }
        } catch (Exception e) {
            logger.error("Error adding rate limit headers: {}", e.getMessage());
        }
    }

    private void sendRateLimitResponse(HttpServletResponse response, String message) throws IOException {
        response.setStatus(SC_TOO_MANY_REQUESTS);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String jsonResponse = String.format(
                "{\"error\": \"Rate limit exceeded\", " +
                        "\"message\": \"%s\", " +
                        "\"retryAfter\": 60}",
                message
        );

        response.getWriter().write(jsonResponse);
        response.getWriter().flush();
    }

    private String buildCacheKey(String userId, String endpoint) {
        return userId + ":" + endpoint;
    }

    private String normalizeEndpoint(String endpoint) {
        for (String pattern : RATE_LIMITS.keySet()) {
            if (endpoint.startsWith(pattern)) {
                return pattern;
            }
        }
        return "default";
    }

    private int getRateLimitForEndpoint(String endpoint) {
        for (Map.Entry<String, Integer> entry : RATE_LIMITS.entrySet()) {
            if (endpoint.startsWith(entry.getKey())) {
                return entry.getValue();
            }
        }
        return RATE_LIMITS.get("default");
    }

    private ExtendedLimitConfig getExtendedLimitForEndpoint(String endpoint) {
        for (Map.Entry<String, ExtendedLimitConfig> entry : EXTENDED_LIMITS.entrySet()) {
            if (endpoint.startsWith(entry.getKey())) {
                return entry.getValue();
            }
        }
        return null;
    }

    private long getResetWindowForEndpoint(String endpoint) {
        // Use configured login reset window for login endpoint, default 60 seconds for others
        if (endpoint.startsWith("/v1/api/auth/login")) {
            return loginResetWindowSeconds;
        }
        return 60; // Default 60 seconds for other endpoints
    }

    private String getUserIdentifier(HttpServletRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication != null && authentication.isAuthenticated()
                && !"anonymousUser".equals(authentication.getPrincipal())) {

            // Extract role from authorities for role-specific rate limiting
            String role = authentication.getAuthorities().stream()
                    .map(GrantedAuthority::getAuthority)
                    .filter(authority -> authority.startsWith("ROLE_"))
                    .map(authority -> authority.substring(5)) // Remove "ROLE_" prefix
                    .findFirst()
                    .orElse("UNKNOWN");

            return "user:" + authentication.getName() + ":role:" + role;
        }

        // For login requests, try to extract user info from request body
        if (request.getRequestURI().startsWith("/v1/api/auth/login") &&
            "POST".equalsIgnoreCase(request.getMethod())) {
            try {
                String loginInfo = extractLoginInfo(request);
                if (loginInfo != null) {
                    return loginInfo;
                }
            } catch (Exception e) {
                logger.debug("Failed to extract login info from request body: {}", e.getMessage());
            }
        }

        return "ip:" + getClientIpAddress(request);
    }

    private String extractLoginInfo(HttpServletRequest request) throws IOException {
        if (!(request instanceof CachedBodyHttpServletRequest)) {
            return null;
        }

        try {
            String body = ((CachedBodyHttpServletRequest) request).getBody();
            if (body != null && !body.trim().isEmpty()) {
                JsonNode jsonNode = objectMapper.readTree(body);
                String email = jsonNode.has("email") ? jsonNode.get("email").asText() : null;
                String role = jsonNode.has("role") ? jsonNode.get("role").asText() : "UNKNOWN";

                if (email != null && !email.trim().isEmpty()) {
                    return "login:" + email + ":role:" + role.toUpperCase();
                }
            }
        } catch (Exception e) {
            logger.debug("Error parsing login request JSON: {}", e.getMessage());
        }

        return null;
    }

    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }

        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }

        return request.getRemoteAddr();
    }

    private boolean shouldSkipRateLimiting(HttpServletRequest request) {
        String path = request.getRequestURI();
        String method = request.getMethod();

        // Skip rate limiting for CORS preflight requests
        if ("OPTIONS".equalsIgnoreCase(method)) {
            return true;
        }

        return path.startsWith("/swagger-ui") ||
                path.startsWith("/v3/api-docs") ||
                path.startsWith("/webjars") ||
                path.equals("/health") ||
                path.equals("/actuator/health") ||
                path.startsWith("/v1/api/auth/register") ||
                path.equals("/") ||
                path.startsWith("/static/");
    }

    public RateLimitStats getRateLimitStats(String userId) {
        long totalBuckets = perMinuteCache.estimatedSize() + extendedCache.estimatedSize();
        Map<String, Integer> userLimits = new ConcurrentHashMap<>();

        // Handle both old format (user:email) and new format (user:email:role:ROLE)
        perMinuteCache.asMap().forEach((key, bucket) -> {
            if (key.startsWith("user:" + userId + ":") || key.equals("user:" + userId)) {
                userLimits.put(key, bucket.getCount());
            }
        });

        return new RateLimitStats(userId, userLimits, totalBuckets);
    }

    public void resetRateLimit(String userId) {
        // Handle both old format (user:email) and new format (user:email:role:ROLE)
        perMinuteCache.asMap().keySet().removeIf(key ->
            key.startsWith("user:" + userId + ":") || key.equals("user:" + userId));
        extendedCache.asMap().keySet().removeIf(key ->
            key.startsWith("user:" + userId + ":") || key.equals("user:" + userId));
        logger.info("Rate limits reset for user: {}", userId);
    }

    public CacheStats getCacheStats() {
        return new CacheStats(
                perMinuteCache.estimatedSize(),
                extendedCache.estimatedSize(),
                perMinuteCache.stats(),
                extendedCache.stats()
        );
    }

    private static class RateLimitBucket {
        private final int limit;
        private final long windowSeconds;
        private final AtomicInteger count;
        private volatile Instant windowStart;

        public RateLimitBucket(int limit, long windowSeconds) {
            this.limit = limit;
            this.windowSeconds = windowSeconds;
            this.count = new AtomicInteger(0);
            this.windowStart = Instant.now();
        }

        public synchronized boolean tryConsume() {
            Instant now = Instant.now();

            if (now.isAfter(windowStart.plusSeconds(windowSeconds))) {
                count.set(0);
                windowStart = now;
            }

            int current = count.incrementAndGet();
            return current <= limit;
        }

        public int getCount() {
            Instant now = Instant.now();
            
            if (now.isAfter(windowStart.plusSeconds(windowSeconds))) {
                return 0;
            }
            
            return count.get();
        }
    }

    private static class ExtendedLimitConfig {
        private final int limit;
        private final int windowMinutes;

        public ExtendedLimitConfig(int limit, int windowMinutes) {
            this.limit = limit;
            this.windowMinutes = windowMinutes;
        }

        public int getLimit() {
            return limit;
        }

        public int getWindowMinutes() {
            return windowMinutes;
        }
    }

    public static class RateLimitStats {
        private final String userId;
        private final Map<String, Integer> currentLimits;
        private final long totalActiveBuckets;

        public RateLimitStats(String userId, Map<String, Integer> currentLimits, long totalActiveBuckets) {
            this.userId = userId;
            this.currentLimits = currentLimits;
            this.totalActiveBuckets = totalActiveBuckets;
        }

        public String getUserId() {
            return userId;
        }

        public Map<String, Integer> getCurrentLimits() {
            return currentLimits;
        }

        public long getTotalActiveBuckets() {
            return totalActiveBuckets;
        }
    }

    public static class CacheStats {
        private final long perMinuteBuckets;
        private final long extendedBuckets;
        private final com.github.benmanes.caffeine.cache.stats.CacheStats perMinuteStats;
        private final com.github.benmanes.caffeine.cache.stats.CacheStats extendedStats;

        public CacheStats(long perMinuteBuckets, long extendedBuckets,
                         com.github.benmanes.caffeine.cache.stats.CacheStats perMinuteStats,
                         com.github.benmanes.caffeine.cache.stats.CacheStats extendedStats) {
            this.perMinuteBuckets = perMinuteBuckets;
            this.extendedBuckets = extendedBuckets;
            this.perMinuteStats = perMinuteStats;
            this.extendedStats = extendedStats;
        }

        public long getPerMinuteBuckets() {
            return perMinuteBuckets;
        }

        public long getExtendedBuckets() {
            return extendedBuckets;
        }

        public com.github.benmanes.caffeine.cache.stats.CacheStats getPerMinuteStats() {
            return perMinuteStats;
        }

        public com.github.benmanes.caffeine.cache.stats.CacheStats getExtendedStats() {
            return extendedStats;
        }
    }

    // Request wrapper to cache request body for multiple reads
    private static class CachedBodyHttpServletRequest extends HttpServletRequestWrapper {
        private final String body;

        public CachedBodyHttpServletRequest(HttpServletRequest request) throws IOException {
            super(request);
            StringBuilder bodyBuilder = new StringBuilder();
            try (BufferedReader reader = request.getReader()) {
                String line;
                while ((line = reader.readLine()) != null) {
                    bodyBuilder.append(line);
                }
            }
            body = bodyBuilder.toString();
        }

        @Override
        public ServletInputStream getInputStream() throws IOException {
            return new CachedBodyServletInputStream(body);
        }

        @Override
        public BufferedReader getReader() throws IOException {
            return new BufferedReader(new InputStreamReader(getInputStream(), StandardCharsets.UTF_8));
        }

        public String getBody() {
            return body;
        }
    }

    // ServletInputStream implementation for cached body
    private static class CachedBodyServletInputStream extends ServletInputStream {
        private final ByteArrayInputStream inputStream;

        public CachedBodyServletInputStream(String body) {
            this.inputStream = new ByteArrayInputStream(body.getBytes(StandardCharsets.UTF_8));
        }

        @Override
        public int read() throws IOException {
            return inputStream.read();
        }

        @Override
        public boolean isFinished() {
            return inputStream.available() == 0;
        }

        @Override
        public boolean isReady() {
            return true;
        }

        @Override
        public void setReadListener(ReadListener readListener) {
            throw new UnsupportedOperationException();
        }
    }
}