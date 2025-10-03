package com.careconnect.security;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@org.springframework.test.context.ActiveProfiles("unit-test")
public class RateLimitingFilterTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void testLoginRateLimit() throws Exception {
        String loginUrl = "/v1/api/auth/login";
        
        // First 5 requests should succeed (or return auth error, but not rate limit)
        for (int i = 1; i <= 5; i++) {
            System.out.println("Request " + i);
            MvcResult result = mockMvc.perform(post(loginUrl)
                    .contentType("application/json")
                    .content("{\"username\":\"test\",\"password\":\"test\"}"))
                    .andExpect(header().exists("X-RateLimit-Limit"))
                    .andExpect(header().string("X-RateLimit-Limit", "5"))
                    .andReturn();
            
            String remaining = result.getResponse().getHeader("X-RateLimit-Remaining");
            System.out.println("Remaining: " + remaining);
            System.out.println("Status: " + result.getResponse().getStatus());
        }
        
        // 6th request should be rate limited
        System.out.println("Request 6 (should be rate limited):");
        mockMvc.perform(post(loginUrl)
                .contentType("application/json")
                .content("{\"username\":\"test\",\"password\":\"test\"}"))
                .andExpect(status().is(429))
                .andExpect(jsonPath("$.error").value("Rate limit exceeded"))
                .andExpect(jsonPath("$.retryAfter").value(60));
    }

    @Test
    public void testAiChatRateLimit() throws Exception {
        String chatUrl = "/v1/api/ai-chat/message";
        
        // Test per-minute limit (10 requests)
        for (int i = 1; i <= 10; i++) {
            System.out.println("Request " + i);
            mockMvc.perform(post(chatUrl)
                    .contentType("application/json")
                    .content("{\"message\":\"test\"}"))
                    .andExpect(header().exists("X-RateLimit-Limit"));
        }
        
        // 11th request should be rate limited
        System.out.println("Request 11 (should be rate limited):");
        mockMvc.perform(post(chatUrl)
                .contentType("application/json")
                .content("{\"message\":\"test\"}"))
                .andExpect(status().is(429));
    }

    @Test
    public void testRateLimitHeaders() throws Exception {
        MvcResult result = mockMvc.perform(post("/v1/api/auth/login")
                .contentType("application/json")
                .content("{\"username\":\"test\",\"password\":\"test\"}"))
                .andExpect(header().exists("X-RateLimit-Limit"))
                .andExpect(header().exists("X-RateLimit-Remaining"))
                .andExpect(header().exists("X-RateLimit-Reset"))
                .andReturn();
        
        System.out.println("Rate Limit Headers:");
        System.out.println("Limit: " + result.getResponse().getHeader("X-RateLimit-Limit"));
        System.out.println("Remaining: " + result.getResponse().getHeader("X-RateLimit-Remaining"));
        System.out.println("Reset: " + result.getResponse().getHeader("X-RateLimit-Reset"));
    }
}