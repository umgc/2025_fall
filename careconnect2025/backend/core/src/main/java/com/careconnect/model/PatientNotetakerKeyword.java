package com.careconnect.model;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.Embeddable;
import lombok.*;


@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Embeddable
public class PatientNotetakerKeyword {
    
    @JsonProperty("keyword")
    private String keyword;
   
    @JsonProperty("event_type")
    private EventType eventType;
   
    public enum EventType {
        ALERT,
        REMINDER,
        APPOINTMENT,
        MEDICATION,
        OTHER
    }
}


