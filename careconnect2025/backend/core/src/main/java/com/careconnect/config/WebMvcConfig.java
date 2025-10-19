package com.careconnect.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:C:/Users/bompl/Documents/uploads/");
     
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // CORS Configuration
        registry.addMapping("/**")
                 .allowedOrigins(
                    "http://localhost:50030",
                    "http://localhost:3000",
                    "https://care-connect-develop.d26kqsucj1bwc1.amplifyapp.com", 
                    "https://isabel-santiagolewis.github.io" // FOR TESTING ONLY
                ) 
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS") // OPTIONS ADDED FOR TESTING ONLY
                .allowedHeaders("*") // FOR TESTING ONLY
                .allowCredentials(true);  // Allow credentials (cookies)
    }
}
