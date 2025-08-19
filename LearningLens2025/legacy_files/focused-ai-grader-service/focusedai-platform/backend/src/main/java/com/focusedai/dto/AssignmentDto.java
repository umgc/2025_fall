package com.focusedai.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public class AssignmentDto {
    private String id;
    private String courseId;
    private String name;
    private String description;
    private String language;
    private LocalDateTime dueDate;
    private double maxScore;
    private List<TestCaseDto> testCases;
    private List<SubmissionDto> submissions;
    private LocalDateTime createdAt;
    private String lmsId;
    private Map<String, Object> metadata;

    // Constructors
    public AssignmentDto() {}

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCourseId() { return courseId; }
    public void setCourseId(String courseId) { this.courseId = courseId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }

    public LocalDateTime getDueDate() { return dueDate; }
    public void setDueDate(LocalDateTime dueDate) { this.dueDate = dueDate; }

    public double getMaxScore() { return maxScore; }
    public void setMaxScore(double maxScore) { this.maxScore = maxScore; }

    public List<TestCaseDto> getTestCases() { return testCases; }
    public void setTestCases(List<TestCaseDto> testCases) { this.testCases = testCases; }

    public List<SubmissionDto> getSubmissions() { return submissions; }
    public void setSubmissions(List<SubmissionDto> submissions) { this.submissions = submissions; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getLmsId() { return lmsId; }
    public void setLmsId(String lmsId) { this.lmsId = lmsId; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
}