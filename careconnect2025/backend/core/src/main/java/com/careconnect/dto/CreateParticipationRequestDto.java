package com.careconnect.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CreateParticipationRequestDto {
    @NotBlank @Size(max = 200)
    private String patientName;

    @NotBlank @Size(max = 64)
    private String maNumber;
}
