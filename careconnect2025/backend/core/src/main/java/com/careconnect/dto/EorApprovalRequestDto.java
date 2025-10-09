package com.careconnect.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EorApprovalRequestDto {
    
    @NotNull
    private Long recordId;
    
    private String comment;
}

