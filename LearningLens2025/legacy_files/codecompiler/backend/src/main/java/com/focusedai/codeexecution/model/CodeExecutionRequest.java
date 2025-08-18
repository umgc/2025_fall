// backend/src/main/java/com/focusedai/codeexecution/model/CodeExecutionRequest.java

package com.focusedai.codeexecution.model;

import java.util.List;

public class CodeExecutionRequest {
    private List<CodeFile> files;
    private String mainClassName;
    private String platform; // "moodle", "classroom", or "test"
    private String assignmentId;
    private String studentId;
    private String input; // 🆕 NEW: Test input support

    // Default constructor
    public CodeExecutionRequest() {}

    // Constructor with required fields
    public CodeExecutionRequest(List<CodeFile> files, String mainClassName) {
        this.files = files;
        this.mainClassName = mainClassName;
    }

    // Constructor with all fields including input
    public CodeExecutionRequest(List<CodeFile> files, String mainClassName, String platform, 
                               String assignmentId, String studentId, String input) {
        this.files = files;
        this.mainClassName = mainClassName;
        this.platform = platform;
        this.assignmentId = assignmentId;
        this.studentId = studentId;
        this.input = input;
    }

    // Getters and Setters
    public List<CodeFile> getFiles() {
        return files;
    }

    public void setFiles(List<CodeFile> files) {
        this.files = files;
    }

    public String getMainClassName() {
        return mainClassName;
    }

    public void setMainClassName(String mainClassName) {
        this.mainClassName = mainClassName;
    }

    public String getPlatform() {
        return platform;
    }

    public void setPlatform(String platform) {
        this.platform = platform;
    }

    public String getAssignmentId() {
        return assignmentId;
    }

    public void setAssignmentId(String assignmentId) {
        this.assignmentId = assignmentId;
    }

    public String getStudentId() {
        return studentId;
    }

    public void setStudentId(String studentId) {
        this.studentId = studentId;
    }

    // 🆕 NEW: Input getter and setter
    public String getInput() {
        return input;
    }

    public void setInput(String input) {
        this.input = input;
    }

    // Utility methods
    public boolean hasInput() {
        return input != null && !input.isEmpty();
    }

    public boolean hasFiles() {
        return files != null && !files.isEmpty();
    }

    public boolean isValid() {
        return hasFiles() && mainClassName != null && !mainClassName.isEmpty();
    }

    // toString method for debugging
    @Override
    public String toString() {
        return "CodeExecutionRequest{" +
                "files=" + files +
                ", mainClassName='" + mainClassName + '\'' +
                ", platform='" + platform + '\'' +
                ", assignmentId='" + assignmentId + '\'' +
                ", studentId='" + studentId + '\'' +
                ", hasInput=" + hasInput() +
                '}';
    }

    // equals and hashCode methods
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        CodeExecutionRequest that = (CodeExecutionRequest) o;

        if (files != null ? !files.equals(that.files) : that.files != null) return false;
        if (mainClassName != null ? !mainClassName.equals(that.mainClassName) : that.mainClassName != null)
            return false;
        if (platform != null ? !platform.equals(that.platform) : that.platform != null) return false;
        if (assignmentId != null ? !assignmentId.equals(that.assignmentId) : that.assignmentId != null)
            return false;
        if (studentId != null ? !studentId.equals(that.studentId) : that.studentId == null) return false;
        return input != null ? input.equals(that.input) : that.input == null;
    }

    @Override
    public int hashCode() {
        int result = files != null ? files.hashCode() : 0;
        result = 31 * result + (mainClassName != null ? mainClassName.hashCode() : 0);
        result = 31 * result + (platform != null ? platform.hashCode() : 0);
        result = 31 * result + (assignmentId != null ? assignmentId.hashCode() : 0);
        result = 31 * result + (studentId != null ? studentId.hashCode() : 0);
        result = 31 * result + (input != null ? input.hashCode() : 0);
        return result;
    }
}