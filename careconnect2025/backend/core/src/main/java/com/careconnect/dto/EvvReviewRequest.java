package com.careconnect.dto;


import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EvvReviewRequest {
    private boolean approve;

    @Size(max = 500)
    private String comment;
}