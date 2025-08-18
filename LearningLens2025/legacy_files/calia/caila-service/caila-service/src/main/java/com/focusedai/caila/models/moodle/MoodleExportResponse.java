package com.focusedai.caila.models.moodle;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MoodleExportResponse {
    private String noteId;
    private String url;
    private String exportType;
    private boolean success;
    private String error;
}
