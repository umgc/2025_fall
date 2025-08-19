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
public class Course {
    private String id;
    private String name;
    private String description;
    private String platform;
    private String instructor;
    private Integer enrollmentCount;
    private LocalDateTime createdAt;
    private List<Assignment> assignments;
}
