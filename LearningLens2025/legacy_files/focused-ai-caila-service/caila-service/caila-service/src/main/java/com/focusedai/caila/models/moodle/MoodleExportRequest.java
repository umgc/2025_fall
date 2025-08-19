package com.focusedai.caila.models.moodle;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MoodleExportRequest {
    private String courseId;
    private String title;
    private String content;
    private String materialType;
    private String exportType;
}