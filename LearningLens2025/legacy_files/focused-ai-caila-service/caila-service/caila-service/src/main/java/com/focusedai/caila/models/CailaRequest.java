package com.focusedai.caila.models;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CailaRequest {
    private String prompt;
    private String role;
    private String courseId;
    private String studentId;
    private String sessionId;
    private String teacherEmail;
    private List<Message> history;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Message {
        private String role;
        private String content;
        private String timestamp;
    }
}