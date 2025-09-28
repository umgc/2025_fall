package com.careconnect.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

/**
 * Development database configuration that disables the custom DatabaseConfig
 * and uses standard Spring Boot database auto-configuration.
 */
@Configuration
@Profile("dev")
@ConditionalOnProperty(name = "spring.profiles.active", havingValue = "dev")
public class DevDatabaseConfig {

    // This configuration class exists to provide a dev-specific database setup
    // When dev profile is active, Spring Boot will use standard datasource configuration
    // from application-dev.properties instead of the custom DatabaseConfig that expects AWS Parameter Store

}