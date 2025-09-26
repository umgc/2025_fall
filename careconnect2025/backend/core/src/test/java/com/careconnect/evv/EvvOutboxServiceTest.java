package com.careconnect.evv;

import com.careconnect.model.EvvParticipant;
import com.careconnect.model.EvvRecord;
import com.careconnect.service.EvvOutboxService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class EvvOutboxServiceTest {

    @Test
    void enqueue_buildsPayload_withCoreFields() {
        var jdbc = mock(NamedParameterJdbcTemplate.class);
        var svc = new EvvOutboxService(jdbc, new ObjectMapper());
        var participant = EvvParticipant.builder().id(1L).maNumber("MA-123").build();
        var rec = EvvRecord.builder().id(55L).participant(participant)
                .serviceType("PCS")
                .timeIn(java.time.OffsetDateTime.parse("2025-09-26T10:00:00Z"))
                .timeOut(java.time.OffsetDateTime.parse("2025-09-26T11:00:00Z"))
                .locationLat(1.23).locationLng(4.56)
                .build();

        svc.enqueue(rec, "dc-sandata");

        ArgumentCaptor<MapSqlParameterSource> cap = ArgumentCaptor.forClass(MapSqlParameterSource.class);
        verify(jdbc).update(startsWith("INSERT INTO evv_outbox"), cap.capture());
        var p = cap.getValue();
        assertThat(p.getValues().get("recordId")).isEqualTo(55L);
        assertThat(p.getValues().get("destination")).isEqualTo("dc-sandata");
        var payload = (java.util.Map<?,?>) p.getValues().get("payload");
        assertThat(payload.get("participant")).isEqualTo("MA-123");
        assertThat(payload.get("serviceType")).isEqualTo("PCS");
    }
}
