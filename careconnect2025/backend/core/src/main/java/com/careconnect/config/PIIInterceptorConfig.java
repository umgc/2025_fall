package com.careconnect.config;

import com.careconnect.security.PIILoggingInterceptor;
import com.careconnect.security.PIIResponseInterceptor;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Configuration class to register PII redaction interceptors.
 */
@Configuration
@RequiredArgsConstructor
public class PIIInterceptorConfig implements WebMvcConfigurer {

    @Autowired
    private PIILoggingInterceptor piiLoggingInterceptor;

    @Autowired
    private PIIResponseInterceptor piiResponseInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // Add PII logging interceptor for all requests
        registry.addInterceptor(piiLoggingInterceptor)
                .addPathPatterns("/**")
                .excludePathPatterns(
                    "/health",
                    "/actuator/**",
                    "/swagger-ui/**",
                    "/v3/api-docs/**",
                    "/webjars/**"
                );

        // Add PII response interceptor for API endpoints
        registry.addInterceptor(piiResponseInterceptor)
                .addPathPatterns("/v1/api/**")
                .excludePathPatterns(
                    "/v1/api/auth/register",
                    "/v1/api/auth/login"
                );
    }
}
