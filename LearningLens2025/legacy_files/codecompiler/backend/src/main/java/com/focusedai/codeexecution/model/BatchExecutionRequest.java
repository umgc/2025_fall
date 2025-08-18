// backend/src/main/java/com/focusedai/codeexecution/model/BatchExecutionRequest.java

package com.focusedai.codeexecution.model;

import java.util.List;

public class BatchExecutionRequest {
    private String assignmentId;
    private String platform;
    private List<SubmissionInfo> submissions;

    // Default constructor
    public BatchExecutionRequest() {}

    // Constructor with parameters
    public BatchExecutionRequest(String assignmentId, String platform, List<SubmissionInfo> submissions) {
        this.assignmentId = assignmentId;
        this.platform = platform;
        this.submissions = submissions;
    }

    // Getters and Setters
    public String getAssignmentId() {
        return assignmentId;
    }

    public void setAssignmentId(String assignmentId) {
        this.assignmentId = assignmentId;
    }

    public String getPlatform() {
        return platform;
    }

    public void setPlatform(String platform) {
        this.platform = platform;
    }

    public List<SubmissionInfo> getSubmissions() {
        return submissions;
    }

    public void setSubmissions(List<SubmissionInfo> submissions) {
        this.submissions = submissions;
    }

    // Inner class for submission information
    public static class SubmissionInfo {
        private String submissionId;
        private String studentId;
        private String studentName;
        private String filename;
        private String code;

        // Default constructor
        public SubmissionInfo() {}

        // Constructor with parameters
        public SubmissionInfo(String submissionId, String studentId, String studentName, String filename, String code) {
            this.submissionId = submissionId;
            this.studentId = studentId;
            this.studentName = studentName;
            this.filename = filename;
            this.code = code;
        }

        // Getters and Setters
        public String getSubmissionId() {
            return submissionId;
        }

        public void setSubmissionId(String submissionId) {
            this.submissionId = submissionId;
        }

        public String getStudentId() {
            return studentId;
        }

        public void setStudentId(String studentId) {
            this.studentId = studentId;
        }

        public String getStudentName() {
            return studentName;
        }

        public void setStudentName(String studentName) {
            this.studentName = studentName;
        }

        public String getFilename() {
            return filename;
        }

        public void setFilename(String filename) {
            this.filename = filename;
        }

        public String getCode() {
            return code;
        }

        public void setCode(String code) {
            this.code = code;
        }

        @Override
        public String toString() {
            return "SubmissionInfo{" +
                    "submissionId='" + submissionId + '\'' +
                    ", studentId='" + studentId + '\'' +
                    ", studentName='" + studentName + '\'' +
                    ", filename='" + filename + '\'' +
                    ", codeLength=" + (code != null ? code.length() : 0) +
                    '}';
        }
    }

    @Override
    public String toString() {
        return "BatchExecutionRequest{" +
                "assignmentId='" + assignmentId + '\'' +
                ", platform='" + platform + '\'' +
                ", submissionCount=" + (submissions != null ? submissions.size() : 0) +
                '}';
    }
}