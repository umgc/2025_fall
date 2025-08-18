package com.focusedai.grading.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

public class Course {
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("name")
    private String name;
    
    @JsonProperty("description")
    private String description;
    
    @JsonProperty("instructor")
    private String instructor;
    
    @JsonProperty("createdAt")
    private LocalDateTime createdAt;
    
    @JsonProperty("assignmentIds")
    private List<String> assignmentIds = new ArrayList<>();
    
    // Constructors
    public Course() {
        this.createdAt = LocalDateTime.now();
    }
    
    // Add all getters and setters for each field
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public String getInstructor() { return instructor; }
    public void setInstructor(String instructor) { this.instructor = instructor; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    
    public List<String> getAssignmentIds() { return assignmentIds; }
    public void setAssignmentIds(List<String> assignmentIds) { this.assignmentIds = assignmentIds; }
}