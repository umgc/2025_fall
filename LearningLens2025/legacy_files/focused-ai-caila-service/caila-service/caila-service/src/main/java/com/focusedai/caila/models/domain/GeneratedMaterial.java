package com.focusedai.caila.models.domain;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GeneratedMaterial {
    private String id;
    private String teacherId;
    private String courseId;
    private String courseName;
    private String title;
    private String type;
    private String content;
    private String prompt;
    private String platform;
    private Integer version;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    @Builder.Default
    private List<MaterialVersion> versions = new ArrayList<>();
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MaterialVersion {
        private Integer version;
        private String content;
        private String prompt;
        private LocalDateTime createdAt;
    }
}