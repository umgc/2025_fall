package com.focusedai.caila.models;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChatRequest {
    private String prompt;
    private String courseId;
    private String materialType;
    private String conversationMode;
}