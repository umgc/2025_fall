package com.focusedai.grading.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;

public class StudentSubmission {
    @JsonProperty("id")
    private String id;
    
    @JsonProperty("studentId")
    private String studentId;
    
    @JsonProperty("studentName")
    private String studentName;
    
    @JsonProperty("filename")
    private String filename;
    
    @JsonProperty("code")
    private String code;
    
    @JsonProperty("assignmentId")
    private String assignmentId;
    
    @JsonProperty("submittedAt")
    private LocalDateTime submittedAt;
    
    @JsonProperty("status")
    private String status = "uploaded";
    
    @JsonProperty("fileSize")
    private Integer fileSize;
    
    @JsonProperty("fileExtension")
    private String fileExtension;
    
    @JsonProperty("gradeId")
    private String gradeId;
    
    // Constructors
    public StudentSubmission() {
        this.submittedAt = LocalDateTime.now();
    }
    
    // Add all getters and setters for each field
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }
    
    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }
    
    public String getFilename() { return filename; }
    public void setFilename(String filename) { this.filename = filename; }
    
    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }
    
    public String getAssignmentId() { return assignmentId; }
    public void setAssignmentId(String assignmentId) { this.assignmentId = assignmentId; }
    
    public LocalDateTime getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(LocalDateTime submittedAt) { this.submittedAt = submittedAt; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public Integer getFileSize() { return fileSize; }
    public void setFileSize(Integer fileSize) { this.fileSize = fileSize; }
    
    public String getFileExtension() { return fileExtension; }
    public void setFileExtension(String fileExtension) { this.fileExtension = fileExtension; }
    
    public String getGradeId() { return gradeId; }
    public void setGradeId(String gradeId) { this.gradeId = gradeId; }
}