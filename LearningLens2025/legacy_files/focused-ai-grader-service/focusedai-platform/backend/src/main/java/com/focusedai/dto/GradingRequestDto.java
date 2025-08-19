package com.focusedai.dto;

import com.focusedai.model.execution.CodeFile;
import java.util.List;

public class GradingRequestDto {
    private String submissionId;
    private String assignmentId;
    private String language;
    private List<CodeFile> files;
    private String testInput;
    private String expectedOutput;
    private String studentId;
    private String studentName;
    private Double maxScore = 100.0;
    private String gradingMode = "AUTO"; // AUTO, MANUAL, HYBRID
    private List<String> customCriteria;

    // Constructors
    public GradingRequestDto() {}

    // Getters and Setters
    public String getSubmissionId() { return submissionId; }
    public void setSubmissionId(String submissionId) { this.submissionId = submissionId; }

    public String getAssignmentId() { return assignmentId; }
    public void setAssignmentId(String assignmentId) { this.assignmentId = assignmentId; }

    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }

    public List<CodeFile> getFiles() { return files; }
    public void setFiles(List<CodeFile> files) { this.files = files; }

    public String getTestInput() { return testInput; }
    public void setTestInput(String testInput) { this.testInput = testInput; }

    public String getExpectedOutput() { return expectedOutput; }
    public void setExpectedOutput(String expectedOutput) { this.expectedOutput = expectedOutput; }

    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public Double getMaxScore() { return maxScore; }
    public void setMaxScore(Double maxScore) { this.maxScore = maxScore; }

    public String getGradingMode() { return gradingMode; }
    public void setGradingMode(String gradingMode) { this.gradingMode = gradingMode; }

    public List<String> getCustomCriteria() { return customCriteria; }
    public void setCustomCriteria(List<String> customCriteria) { this.customCriteria = customCriteria; }
}