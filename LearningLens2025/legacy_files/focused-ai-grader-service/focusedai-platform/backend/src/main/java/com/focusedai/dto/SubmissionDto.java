package com.focusedai.dto;

import com.focusedai.model.execution.CodeFile;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public class SubmissionDto {
    private String id;
    private String assignmentId;
    private String studentId;
    private String studentName;
    private List<CodeFile> files;
    private LocalDateTime submittedAt;
    private String status;
    private GradeDto grade;
    private boolean isZipSubmission;
    private String lmsId;
    private Map<String, Object> metadata;

    // Constructors
    public SubmissionDto() {}

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getAssignmentId() { return assignmentId; }
    public void setAssignmentId(String assignmentId) { this.assignmentId = assignmentId; }

    public String getStudentId() { return studentId; }
    public void setStudentId(String studentId) { this.studentId = studentId; }

    public String getStudentName() { return studentName; }
    public void setStudentName(String studentName) { this.studentName = studentName; }

    public List<CodeFile> getFiles() { return files; }
    public void setFiles(List<CodeFile> files) { this.files = files; }

    public LocalDateTime getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(LocalDateTime submittedAt) { this.submittedAt = submittedAt; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public GradeDto getGrade() { return grade; }
    public void setGrade(GradeDto grade) { this.grade = grade; }

    public boolean isZipSubmission() { return isZipSubmission; }
    public void setZipSubmission(boolean zipSubmission) { isZipSubmission = zipSubmission; }

    public String getLmsId() { return lmsId; }
    public void setLmsId(String lmsId) { this.lmsId = lmsId; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
}