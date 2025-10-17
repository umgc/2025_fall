package com.careconnect.service.chat;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;

@Configuration
public class AwsClientsConfig {

    @Bean
    public AwsCredentialsProvider awsCredentialsProvider() {
        // Uses the default provider chain: env vars, system props, web identity, profile, container, instance profile
        return DefaultCredentialsProvider.create();
    }
}
