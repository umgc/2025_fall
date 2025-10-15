package com.careconnect.evv;

import com.careconnect.model.evv.EvvRecord;
import com.careconnect.model.evv.EvvAuditEvent;
import com.careconnect.repository.evv.EvvAuditEventRepository;
import com.careconnect.service.evv.AuditLogger;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class AuditTrailBehaviorTest {

    @Test
    void auditLogger_appendsEvents_forCreateAndConfirm() {
        var audit = spy(new AuditLogger(null));
        // spy over a stub: override repo.save to be no-op by subclassing (simplify with mock)
        var repo = mock(EvvAuditEventRepository.class);
        var logger = new AuditLogger(repo);

        var rec = EvvRecord.builder().id(1L).deviceInfo(Map.of("device","JUnit")).build();
        logger.log(rec, 100L, "CREATED", Map.of());
        logger.log(rec, 100L, "CONFIRMED", Map.of("comment","ok"));

        ArgumentCaptor<EvvAuditEvent> cap = ArgumentCaptor.forClass(EvvAuditEvent.class);
        verify(repo, times(2)).save(cap.capture());
        var events = cap.getAllValues();
        assertThat(events).extracting("eventType").containsExactly("CREATED","CONFIRMED");
        assertThat(events).allMatch(e -> ((EvvAuditEvent)e).getEvvRecord().getId().equals(1L));
    }
}
