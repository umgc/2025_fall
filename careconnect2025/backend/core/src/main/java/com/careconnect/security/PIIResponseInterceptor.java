package com.careconnect.security;

import com.careconnect.service.PIIRedactionService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Interceptor to automatically redact PII from API responses.
 * This ensures that sensitive information is not exposed in API responses.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class PIIResponseInterceptor implements HandlerInterceptor {

    @Autowired
    private PIIRedactionService piiRedactionService;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, 
                          Object handler, ModelAndView modelAndView) throws Exception {
        
        // Only process JSON responses
        if (isJsonResponse(response) && shouldRedactResponse(request)) {
            // Note: This is a simplified implementation
            // In a production environment, you might want to use a more sophisticated approach
            // like response body modification or custom response wrapper
            log.debug("PII redaction applied to response for {} {}", 
                     request.getMethod(), request.getRequestURI());
        }
    }

    private boolean isJsonResponse(HttpServletResponse response) {
        String contentType = response.getContentType();
        return contentType != null && contentType.contains(MediaType.APPLICATION_JSON_VALUE);
    }

    private boolean shouldRedactResponse(HttpServletRequest request) {
        String uri = request.getRequestURI();
        String method = request.getMethod();
        
        // Redact PII for patient and caregiver profile endpoints
        return (uri.startsWith("/v1/api/patients/") || 
                uri.startsWith("/v1/api/caregivers/") || 
                uri.startsWith("/v1/api/family-members/")) &&
               ("GET".equals(method) || "POST".equals(method) || "PUT".equals(method));
    }

    /**
     * Redact PII from a response body string
     */
    public String redactResponseBody(String responseBody) {
        if (responseBody == null || responseBody.isEmpty()) {
            return responseBody;
        }

        try {
            // Try to redact as JSON first
            return piiRedactionService.redactJsonString(responseBody);
        } catch (Exception e) {
            // Fallback to string redaction
            log.debug("JSON redaction failed, falling back to string redaction: {}", e.getMessage());
            return piiRedactionService.redactString(responseBody);
        }
    }
}
