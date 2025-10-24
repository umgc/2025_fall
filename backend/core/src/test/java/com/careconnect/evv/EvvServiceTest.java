package com.careconnect.evv;

import com.careconnect.dto.evv.CreateParticipationRequestDto;
import com.careconnect.dto.evv.EvvRecordRequestDto;
import com.careconnect.model.evv.EvvParticipant;
import com.careconnect.model.evv.EvvRecord;
import com.careconnect.repository.evv.EvvParticipantRepository;
import com.careconnect.repository.evv.EvvRecordRepository;
import com.careconnect.service.evv.AuditLogger;
import com.careconnect.service.evv.EvvService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;
import java.time.*;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class EvvServiceTest {

    @Mock EvvParticipantRepository participantRepo;
    @Mock EvvRecordRepository recordRepo;
    @Mock AuditLogger audit;
    @InjectMocks EvvService service;

    @BeforeEach void setUp(){ MockitoAnnotations.openMocks(this); }

    @Test
    void createParticipant_createsNew_whenNotExists() {
        var req = CreateParticipationRequestDto.builder().patientName("Alice").maNumber("MA-1").build();
        when(participantRepo.findByMaNumber("MA-1")).thenReturn(Optional.empty());
        when(participantRepo.save(any())).thenAnswer(i -> {
            EvvParticipant p = i.getArgument(0);
            p.setId(10L);
            return p;
        });

        var out = service.createParticipant(req, "caregiver@x.org");

        assertThat(out.getId()).isEqualTo(10L);
        assertThat(out.getPatientName()).isEqualTo("Alice");
        assertThat(out.getMaNumber()).isEqualTo("MA-1");
        assertThat(out.getCreatedBy()).isEqualTo("caregiver@x.org");
        verify(participantRepo).save(any(EvvParticipant.class));
    }

    @Test
    void createRecord_setsPendingReview_andAuditsCreate() {
        var participant = EvvParticipant.builder().id(1L).patientName("Bob").maNumber("MA-2").build();
        when(participantRepo.findByMaNumber("MA-2")).thenReturn(Optional.of(participant));
        when(recordRepo.save(any())).thenAnswer(i -> {
            EvvRecord r = i.getArgument(0);
            r.setId(77L);
            return r;
        });

        var req = EvvRecordRequestDto.builder()
                .serviceType("PCS")
                .individualName("Bob")
                .caregiverId(42L)
                .dateOfService(LocalDate.of(2025,9,26))
                .timeIn(OffsetDateTime.parse("2025-09-26T13:00:00Z"))
                .timeOut(OffsetDateTime.parse("2025-09-26T14:00:00Z"))
                .locationLat(38.9).locationLng(-77.03).locationSource("gps")
                .participantMaNumber("MA-2")
                .stateCode("DC")
                .deviceInfo(Map.of("device","test"))
                .build();

        var r = service.createRecord(req, 42L);

        assertThat(r.getId()).isEqualTo(77L);
        assertThat(r.getStatus()).isEqualTo("PENDING_REVIEW");
        assertThat(r.getServiceType()).isEqualTo("PCS");
        assertThat(r.getParticipant().getMaNumber()).isEqualTo("MA-2");
        verify(audit).log(any(EvvRecord.class), eq(42L), eq("CREATED"), isNull());
    }

    @Test
    void review_approve_transitionsToConfirmed_andAudits() {
        var rec = EvvRecord.builder().id(5L).status("PENDING_REVIEW").build();
        when(recordRepo.findById(5L)).thenReturn(Optional.of(rec));

        var out = service.review(5L, true, 123L, "ok");

        assertThat(out.getStatus()).isEqualTo("CONFIRMED");
        verify(recordRepo).save(rec);
        verify(audit).log(rec, 123L, "CONFIRMED", Map.of("comment","ok"));
    }

    @Test
    void review_reject_staysPendingReview_andAuditsReviewed() {
        var rec = EvvRecord.builder().id(6L).status("PENDING_REVIEW").build();
        when(recordRepo.findById(6L)).thenReturn(Optional.of(rec));

        var out = service.review(6L, false, 321L, "fix times");

        assertThat(out.getStatus()).isEqualTo("PENDING_REVIEW");
        verify(audit).log(rec, 321L, "REVIEWED", Map.of("comment","fix times"));
    }
}