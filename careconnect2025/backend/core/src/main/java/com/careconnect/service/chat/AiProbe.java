package com.careconnect.service.chat;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;

@Component
@RequiredArgsConstructor
class AiProbe {
    private final org.springframework.ai.chat.model.ChatModel chatModel;
    private final AwsCredentialsProvider creds;


    @PostConstruct
    void logModel() {
        System.out.println("ChatModel bean: " + chatModel.getClass().getName());
    }
    @PostConstruct
    void logIdentity() {
        var ak = creds.resolveCredentials().accessKeyId();
        String partial = ak.length() >= 8 ? ak.substring(0,4) + "..." + ak.substring(ak.length()-4) : ak;
        System.out.println("AWS Access key"+ partial);
    }
}
