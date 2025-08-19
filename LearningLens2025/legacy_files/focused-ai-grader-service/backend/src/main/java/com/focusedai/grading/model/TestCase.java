package com.focusedai.grading.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TestCase {
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("input")
    private String input;
    
    @JsonProperty("expectedOutput")
    private String expectedOutput;
    
    @JsonProperty("points")
    private int points = 1;
    
    @JsonProperty("isVisible")
    private boolean isVisible = true;
    
    // Constructors
    public TestCase() {}
    
    // Getters and Setters (generate these in your IDE)
    // ... (include all getters and setters)
}