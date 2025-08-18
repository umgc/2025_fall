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
public class Assignment {
    private String id;
    private String courseId;
    private String name;
    private String description;
    private String language;
    private LocalDateTime dueDate;
    private Double maxScore;
    private String platform;
    private String status;
    private Integer submissionCount;
    private LocalDateTime createdAt;
    private List<Submission> submissions;
}