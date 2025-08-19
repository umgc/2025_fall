package com.focusedai.caila.models;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MaterialRequest {
    private String title;
    private String materialType;
    private String content;
    private String prompt;
    private String courseId;
    private String courseName;
}