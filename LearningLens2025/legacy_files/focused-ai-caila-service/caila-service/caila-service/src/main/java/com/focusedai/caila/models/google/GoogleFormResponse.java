package com.focusedai.caila.models.google;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GoogleFormResponse {
    private String formId;
    private String formUrl;
    private String editUrl;
    private boolean success;
    private String error;
}
