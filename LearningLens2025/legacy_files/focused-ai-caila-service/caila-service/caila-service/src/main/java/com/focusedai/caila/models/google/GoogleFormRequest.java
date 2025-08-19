package com.focusedai.caila.models.google;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GoogleFormRequest {
    private String title;
    private String description;
    private List<Question> questions;
    private Map<String, Object> settings;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Question {
        private String title;
        private String type;
        private List<String> options;
        private boolean required;
    }
}