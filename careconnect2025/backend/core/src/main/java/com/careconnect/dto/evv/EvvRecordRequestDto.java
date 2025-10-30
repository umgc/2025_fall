package com.careconnect.dto.evv;

import jakarta.validation.constraints.*;
import lombok.*;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.Map;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class EvvRecordRequestDto {
    @NotBlank @Size(max = 128)
    private String serviceType;

    @NotBlank @Size(max = 200)
    private String individualName;

    @NotNull @Positive
    private Long caregiverId;

    @NotNull
    private LocalDate dateOfService;

    @NotNull
    private OffsetDateTime timeIn;

    @NotNull
    private OffsetDateTime timeOut;

    @DecimalMin(value = "-90.0", inclusive = true) @DecimalMax(value = "90.0", inclusive = true)
    private Double locationLat;

    @DecimalMin(value = "-180.0", inclusive = true) @DecimalMax(value = "180.0", inclusive = true)
    private Double locationLng;

    @NotBlank @Pattern(regexp = "gps|manual")
    private String locationSource;

    @NotNull @Positive
    private Long patientId; // Direct reference to patient receiving care

    @NotBlank @Pattern(regexp = "MD|DC|VA")
    private String stateCode;

    private Map<String, Object> deviceInfo;
}
