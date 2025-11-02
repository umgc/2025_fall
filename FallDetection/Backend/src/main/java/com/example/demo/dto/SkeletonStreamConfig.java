package com.example.demo.dto;

import lombok.Data;

@Data
public class SkeletonStreamConfig {
    private String mqttUsername;
    private String mqttPassword;
    private String wssUrl;
    private Long groupId;
    private String serialNumber;
    private Long streamToken;
    private String publishTopic;
    private String subscribeTopic;
}