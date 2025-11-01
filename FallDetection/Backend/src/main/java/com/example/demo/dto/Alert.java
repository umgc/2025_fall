package com.example.demo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class Alert {
    private String id;
    
    @JsonProperty("alert_type")
    private String alertType;
    
    @JsonProperty("camera_serial_number")
    private String cameraSerialNumber;
    
    @JsonProperty("created_at")
    private Long createdAt;  // For frontend compatibility
    
    @JsonProperty("skeleton_file")
    private String skeletonFile;
    
    // Additional fields from API
    @JsonProperty("event_type")
    private Integer eventType;
    
    @JsonProperty("serial_number")
    private String serialNumber;
    
    @JsonProperty("person_name")
    private String personName;
    
    @JsonProperty("room_name")
    private String roomName;
    
    @JsonProperty("camera_name")
    private String cameraName;
    
    @JsonProperty("is_resolved")
    private Boolean isResolved;
    
    @JsonProperty("background_url")
    private String backgroundUrl;
}