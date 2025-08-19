package com.focusedai.caila.models.moodle;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MoodleNote {
    private String id;
    private String userId;
    private String courseId;
    private String content;
    private String publishState;
    private LocalDateTime created;
    private LocalDateTime lastModified;
}