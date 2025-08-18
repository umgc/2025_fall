package com.focusedai.caila.models.domain;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatLog {
    private String id;
    private String userId;
    private String courseId;
    private String prompt;
    private String response;
    private String platform;
    private LocalDateTime timestamp;
    private String sessionId;
}
