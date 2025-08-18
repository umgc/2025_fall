package com.focusedai.caila.models;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CailaResponse {
    private String response;
    private String materialId;
    private String sessionId;
    private LocalDateTime timestamp;
    private boolean success;
    private String error;
}