package com.careconnect.evv;

import com.careconnect.model.EvvParticipant;
import com.careconnect.model.EvvRecord;
import com.careconnect.service.AuditLogger;
import com.careconnect.service.EvvOutboxService;
import com.careconnect.service.EvvSubmissionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;

import static org.mockito.Mockito.*;

class EvvSubmissionServiceTest {

    @Mock EvvOutboxService outbox;
    @Mock AuditLogger audit;
    @InjectMocks EvvSubmissionService svc;

    @BeforeEach void setUp(){ MockitoAnnotations.openMocks(this); }

    @Test
    void destinationFor_mapsStates() {
        assert "maryland-info-only".equals(svc.destinationFor("MD"));
        assert "dc-sandata".equals(svc.destinationFor("DC"));
        assert "virginia-mco".equals(svc.destinationFor("VA"));
    }

    @Test
    void queueForSubmission_enqueuesToDestination_andAudits() {
        var rec = EvvRecord.builder()
                .id(9L)
                .participant(EvvParticipant.builder().id(1L).maNumber("MA-9").build())
                .stateCode("VA").build();

        svc.queueForSubmission(rec, 777L);

        verify(outbox).enqueue(rec, "virginia-mco");
        verify(audit).log(rec, 777L, "SUBMISSION_QUEUED", java.util.Map.of());
    }
}
