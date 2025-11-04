package com.careconnect.dto.evv;

import com.careconnect.model.evv.EvvLocationRole;
import com.careconnect.model.evv.EvvLocationType;
import jakarta.validation.constraints.*;
import lombok.*;

import java.math.BigDecimal;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EvvLocationRequest {
    
    @NotNull(message = "EVV record ID is required")
    private Long evvRecordId;
    
    @NotNull(message = "Location role is required")
    private EvvLocationRole role;
    
    @NotNull(message = "Location type is required")
    private EvvLocationType type;
    
    private CoordinatesDto coords;
    
    /**
     * Nested DTO for GPS coordinates
     */
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CoordinatesDto {
        
        @NotNull(message = "Latitude is required for GPS location")
        @DecimalMin(value = "-90.0", message = "Latitude must be between -90 and 90")
        @DecimalMax(value = "90.0", message = "Latitude must be between -90 and 90")
        private BigDecimal lat;
        
        @NotNull(message = "Longitude is required for GPS location")
        @DecimalMin(value = "-180.0", message = "Longitude must be between -180 and 180")
        @DecimalMax(value = "180.0", message = "Longitude must be between -180 and 180")
        private BigDecimal lng;
        
        @DecimalMin(value = "0.0", message = "Accuracy must be positive")
        private BigDecimal accuracyM;
    }
    
    /**
     * Validate the request based on location type
     */
    public void validate() {
        if (type == EvvLocationType.GPS) {
            if (coords == null || coords.getLat() == null || coords.getLng() == null) {
                throw new IllegalArgumentException("GPS location requires coordinates");
            }
        }
        // PATIENT_ADDRESS doesn't need coords - address will be fetched from patient
    }
}

