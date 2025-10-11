package com.careconnect.evv;

import org.junit.jupiter.api.Test;
import java.time.*;
import com.careconnect.dto.evv.CreateParticipationRequestDto;
import com.careconnect.dto.evv.EvvRecordRequestDto;
import static org.assertj.core.api.Assertions.assertThat;

public class EvvControllerTest {
    @Test void buildRecordRequest(){
        var req = EvvRecordRequestDto.builder()
                .serviceType("PCS")
                .individualName("John Doe")
                .caregiverId(1L)
                .dateOfService(LocalDate.now())
                .timeIn(OffsetDateTime.now())
                .timeOut(OffsetDateTime.now().plusHours(2))
                .locationSource("gps")
                .participantMaNumber("MA123")
                .stateCode("DC")
                .build();
        assertThat(req.getServiceType()).isEqualTo("PCS");
    }

    @Test void createParticipantDto(){
        var p = CreateParticipationRequestDto.builder().patientName("Jane Roe").maNumber("MA999").build();
        assertThat(p.getPatientName()).isEqualTo("Jane Roe");
    }
}
