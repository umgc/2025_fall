package com.focusedai.utils;

import com.focusedai.utils.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.HashMap;

@Component
public class UserContextExtractor {
    
    @Autowired
    private JwtUtil jwtUtil;
    
    /**
     * Extract user information from JWT token provided by parent system
     */
    public Map<String, Object> extractUserInfo(String userContext) {
        Map<String, Object> userInfo = new HashMap<>();
        
        if (userContext == null || userContext.isEmpty()) {
            // Return default/anonymous context
            userInfo.put("anonymous", true);
            userInfo.put("userId", "anonymous");
            userInfo.put("lms", "unknown");
            return userInfo;
        }
        
        try {
            // Remove Bearer prefix if present
            String token = userContext.startsWith("Bearer ") ? 
                userContext.substring(7) : userContext;
            
            // Validate token
            if (!jwtUtil.validateToken(token)) {
                userInfo.put("error", "Invalid token");
                return userInfo;
            }
            
            // Extract user information
            userInfo.put("userId", jwtUtil.extractUserId(token));
            userInfo.put("lms", jwtUtil.extractLMS(token));
            userInfo.put("userIdentifier", jwtUtil.extractUserIdentifier(token));
            userInfo.put("role", jwtUtil.extractUserRole(token));
            userInfo.put("isGoogleUser", jwtUtil.isGoogleUser(token));
            userInfo.put("isMoodleUser", jwtUtil.isMoodleUser(token));
            userInfo.put("anonymous", false);
            userInfo.put("valid", true);
            
            // Extract LMS-specific data if needed
            if (jwtUtil.isGoogleUser(token)) {
                userInfo.put("googleAccessToken", jwtUtil.extractGoogleAccessToken(token));
                userInfo.put("googleRefreshToken", jwtUtil.extractGoogleRefreshToken(token));
                userInfo.put("googleTokenExpiry", jwtUtil.extractGoogleTokenExpiry(token));
                userInfo.put("isGoogleTokenExpired", jwtUtil.isGoogleTokenExpired(token));
            } else if (jwtUtil.isMoodleUser(token)) {
                userInfo.put("moodleDomain", jwtUtil.extractMoodleDomain(token));
                userInfo.put("webServiceToken", jwtUtil.extractWebServiceToken(token));
            }
            
        } catch (Exception e) {
            System.err.println("❌ Error extracting user context: " + e.getMessage());
            userInfo.put("error", "Token extraction failed: " + e.getMessage());
            userInfo.put("anonymous", true);
        }
        
        return userInfo;
    }
    
    /**
     * Check if user has valid context
     */
    public boolean isValidUserContext(String userContext) {
        Map<String, Object> userInfo = extractUserInfo(userContext);
        return Boolean.TRUE.equals(userInfo.get("valid")) && !Boolean.TRUE.equals(userInfo.get("anonymous"));
    }
    
    /**
     * Get user ID from context
     */
    public String getUserId(String userContext) {
        Map<String, Object> userInfo = extractUserInfo(userContext);
        return (String) userInfo.get("userId");
    }
    
    /**
     * Get LMS type from context
     */
    public String getLmsType(String userContext) {
        Map<String, Object> userInfo = extractUserInfo(userContext);
        return (String) userInfo.get("lms");
    }
}