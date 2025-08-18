package com.focusedai.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public class CourseDto {
    private String id;
    private String name;
    private String description;
    private String platform;
    private String lmsId;
    private String instructor;
    private int enrollmentCount;
    private LocalDateTime createdAt;
    private List<AssignmentDto> assignments;
    private Map<String, Object> metadata;

    // Constructors
    public CourseDto() {}

    public CourseDto(String id, String name, String platform) {
        this.id = id;
        this.name = name;
        this.platform = platform;
        this.createdAt = LocalDateTime.now();
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getPlatform() { return platform; }
    public void setPlatform(String platform) { this.platform = platform; }

    public String getLmsId() { return lmsId; }
    public void setLmsId(String lmsId) { this.lmsId = lmsId; }

    public String getInstructor() { return instructor; }
    public void setInstructor(String instructor) { this.instructor = instructor; }

    public int getEnrollmentCount() { return enrollmentCount; }
    public void setEnrollmentCount(int enrollmentCount) { this.enrollmentCount = enrollmentCount; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public List<AssignmentDto> getAssignments() { return assignments; }
    public void setAssignments(List<AssignmentDto> assignments) { this.assignments = assignments; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
}