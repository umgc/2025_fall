package com.careconnect.service.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;
import java.util.List;
import java.util.ArrayList;
import java.util.regex.Pattern;

@Service
@Slf4j
public class InputSanitizationService {

    @Autowired
    private SecurityAuditService securityAuditService;

    // Patterns for detecting potentially harmful content
    private static final Pattern SQL_INJECTION_PATTERN = Pattern.compile(
        "(?i).*(union|select|insert|update|delete|drop|alter|create|exec|execute|script|javascript|vbscript).*"
    );

    private static final Pattern XSS_PATTERN = Pattern.compile(
        "(?i).*(<script|javascript:|vbscript:|onload=|onerror=|onclick=|onmouseover=).*"
    );

    private static final Pattern PROMPT_INJECTION_PATTERN = Pattern.compile(
        "(?i).*(ignore previous|forget previous|system prompt|you are now|new instructions|disregard|override).*"
    );

    public static class SanitizationResult {
        private final String sanitizedContent;
        private final boolean isBlocked;
        private final List<String> issues;

        public SanitizationResult(String sanitizedContent, boolean isBlocked, List<String> issues) {
            this.sanitizedContent = sanitizedContent;
            this.isBlocked = isBlocked;
            this.issues = issues;
        }

        public String getSanitizedContent() { return sanitizedContent; }
        public boolean isBlocked() { return isBlocked; }
        public List<String> getIssues() { return issues; }
    }

    public SanitizationResult sanitizeUserInput(String input, Long userId, String conversationId) {
        if (input == null || input.trim().isEmpty()) {
            return new SanitizationResult("", false, new ArrayList<>());
        }

        List<String> issues = new ArrayList<>();
        boolean shouldBlock = false;

        // Check for SQL injection attempts
        if (SQL_INJECTION_PATTERN.matcher(input).matches()) {
            issues.add("Potential SQL injection detected");
            shouldBlock = true;
            securityAuditService.logSecurityViolation(userId, conversationId, "SQL_INJECTION_ATTEMPT", input.length() + " chars");
        }

        // Check for XSS attempts
        if (XSS_PATTERN.matcher(input).matches()) {
            issues.add("Potential XSS detected");
            shouldBlock = true;
            securityAuditService.logSecurityViolation(userId, conversationId, "XSS_ATTEMPT", input.length() + " chars");
        }

        // Check for prompt injection attempts
        if (PROMPT_INJECTION_PATTERN.matcher(input).matches()) {
            issues.add("Potential prompt injection detected");
            shouldBlock = true;
            securityAuditService.logSecurityViolation(userId, conversationId, "PROMPT_INJECTION_ATTEMPT", input.length() + " chars");
        }

        if (shouldBlock) {
            return new SanitizationResult("", true, issues);
        }

        // Basic sanitization - remove potentially harmful characters
        String sanitized = input
            .replaceAll("<script[^>]*>.*?</script>", "")
            .replaceAll("(?i)javascript:", "")
            .replaceAll("(?i)vbscript:", "")
            .trim();

        if (!sanitized.equals(input)) {
            securityAuditService.logSanitizationAction(userId, conversationId, "INPUT_SANITIZED", "Removed potentially harmful content");
        }

        return new SanitizationResult(sanitized, false, issues);
    }

    public SanitizationResult sanitizeSystemPrompt(String prompt, Long userId, String conversationId) {
        if (prompt == null || prompt.trim().isEmpty()) {
            return new SanitizationResult("", false, new ArrayList<>());
        }

        // System prompts have stricter validation
        List<String> issues = new ArrayList<>();
        boolean shouldBlock = false;

        // Check for suspicious patterns that might be injected
        if (prompt.contains("ignore") || prompt.contains("forget") || prompt.contains("disregard")) {
            issues.add("System prompt contains suspicious override instructions");
            shouldBlock = true;
            securityAuditService.logSecurityViolation(userId, conversationId, "SYSTEM_PROMPT_INJECTION", "Suspicious override detected");
        }

        if (shouldBlock) {
            return new SanitizationResult("", true, issues);
        }

        return new SanitizationResult(prompt, false, issues);
    }
}