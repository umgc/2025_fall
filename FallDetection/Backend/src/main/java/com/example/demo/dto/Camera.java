package com.example.demo.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class Camera {
    private Long id;
    
    @JsonProperty("serial_number")
    private String serialNumber;
    
    @JsonProperty("friendly_name")
    private String friendlyName;
    
    @JsonProperty("room_name")
    private String roomName;
    
    @JsonProperty("is_online")
    private Boolean isOnline;
    
    private String model;
    private String version;
}