package com.focusedai.grading.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

public class Assignment {
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("description")
    private String description;
    
    @JsonProperty("language")
    private String language;
    
    @JsonProperty("timeoutSeconds")
    private int timeoutSeconds = 30;
    
    @JsonProperty("maxScore")
    private int maxScore;
    
    @JsonProperty("testCases")
    private List<TestCase> testCases = new ArrayList<>();
    
    @JsonProperty("createdAt")
    private LocalDateTime createdAt;
    
    @JsonProperty("createdBy")
    private String createdBy;
    
    // Constructors
    public Assignment() {
        this.createdAt = LocalDateTime.now();
    }
    
    // Getters and Setters (generate these in your IDE)
    // ... (include all getters and setters for each field)
}