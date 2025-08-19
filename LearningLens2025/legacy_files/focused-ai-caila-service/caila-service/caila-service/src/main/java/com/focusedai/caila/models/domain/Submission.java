package com.focusedai.caila.models.domain;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Submission {
    private String id;
    private String assignmentId;
    private String studentId;
    private String studentName;
    private LocalDateTime submittedAt;
    private String status;
    private List<CodeFile> files;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CodeFile {
        private String filename;
        private String content;
        private String language;
    }
}
