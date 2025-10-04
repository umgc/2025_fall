package com.careconnect.security;

import com.careconnect.service.PIIRedactionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

/**
 * Interceptor to automatically redact PII from log messages and error responses.
 * This ensures that sensitive information is not exposed in application logs.
 */
@Component
@Slf4j
@RequiredArgsConstructor
public class PIILoggingInterceptor implements HandlerInterceptor {

    @Autowired
    private PIIRedactionService piiRedactionService;

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, 
                               Object handler, Exception ex) throws Exception {
        if (ex != null) {
            // Redact PII from exception messages before logging
            String redactedMessage = piiRedactionService.redactForLogging(ex.getMessage());
            log.error("Request failed for {} {}: {}", 
                     request.getMethod(), 
                     request.getRequestURI(), 
                     redactedMessage);
        }
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, 
                          Object handler, ModelAndView modelAndView) throws Exception {
        // Log request completion with redacted information
        if (log.isDebugEnabled()) {
            String userAgent = piiRedactionService.redactForLogging(request.getHeader("User-Agent"));
            String referer = piiRedactionService.redactForLogging(request.getHeader("Referer"));
            
            log.debug("Request completed: {} {} - Status: {} - User-Agent: {} - Referer: {}", 
                     request.getMethod(), 
                     request.getRequestURI(), 
                     response.getStatus(),
                     userAgent,
                     referer);
        }
    }
}
