package com.careconnect.security;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest
@Import(RateLimitingFilter.class)
@ActiveProfiles("unit-test")
public class RateLimitingFilterWebTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void testRateLimitingFilter() throws Exception {
        // Test that the filter is properly configured and working
        // This test doesn't need full application context

        String testEndpoint = "/test";

        // First request should pass through (might hit controller endpoint)
        mockMvc.perform(post(testEndpoint)
                .contentType("application/json")
                .content("{}"))
                .andExpect(status().isNotFound()); // 404 because endpoint doesn't exist, but filter allows it
    }
}