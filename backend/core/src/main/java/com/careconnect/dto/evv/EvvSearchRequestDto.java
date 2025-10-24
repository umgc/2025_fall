package com.careconnect.dto.evv;

import lombok.*;

import java.time.LocalDate;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EvvSearchRequestDto {
    
    private String patientName;
    private String serviceType;
    private Long caregiverId;
    private LocalDate startDate;
    private LocalDate endDate;
    private String stateCode;
    private String status;
    private Integer page = 0;
    private Integer size = 20;
    private String sortBy = "createdAt";
    private String sortDirection = "DESC";
}

