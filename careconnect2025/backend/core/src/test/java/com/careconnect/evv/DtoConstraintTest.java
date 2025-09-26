package com.careconnect.evv;

import com.careconnect.dto.CreateParticipationRequestDto;
import com.careconnect.dto.EvvRecordRequestDto;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class DtoConstraintTest {
    static Validator validator;

    @BeforeAll static void init(){
        validator = Validation.buildDefaultValidatorFactory().getValidator();
    }

    @Test
    void createParticipantRequest_requiresFields() {
        var req = CreateParticipationRequestDto.builder().patientName("").maNumber("").build();
        var violations = validator.validate(req);
        assertThat(violations).isNotEmpty();
    }

    @Test
    void evvRecordRequest_coreFieldsValid() {
        var req = EvvRecordRequestDto.builder()
                .serviceType("PCS")
                .individualName("Jane")
                .caregiverId(1L)
                .dateOfService(LocalDate.now())
                .timeIn(OffsetDateTime.now())
                .timeOut(OffsetDateTime.now().plusMinutes(30))
                .locationSource("gps")
                .participantMaNumber("MA-555")
                .stateCode("MD")
                .deviceInfo(Map.of("device","JUnit"))
                .build();
        var violations = validator.validate(req);
        assertThat(violations).isEmpty();
    }
}
