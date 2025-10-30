package com.careconnect.service.evv;

import com.careconnect.model.evv.EvvRecord;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service @RequiredArgsConstructor
public class EvvOutboxService {
    private final NamedParameterJdbcTemplate jdbc;
    private final ObjectMapper objectMapper;

    public void enqueue(EvvRecord record, String destination) {
        Map<String,Object> payload = Map.of(
                "id", record.getId(),
                "patient", record.getPatient().getMaNumber(),
                "serviceType", record.getServiceType(),
                "timeIn", record.getTimeIn(),
                "timeOut", record.getTimeOut(),
                "loc", Map.of("lat", record.getLocationLat(), "lng", record.getLocationLng())
        );
        var params = new MapSqlParameterSource().addValue("recordId", record.getId())
                .addValue("destination", destination)
                .addValue("payload", payload);
        jdbc.update("""
                INSERT INTO evv_outbox (evv_record_id, destination, payload)
                VALUES (:recordId, :destination, to_jsonb(:payload::json))
                """, params);
    }

    public void markSent(Long id) {
        jdbc.update("UPDATE evv_outbox SET status='SENT' WHERE id=:id", new MapSqlParameterSource("id", id));
    }
    public void markFailed(Long id, String err) {
        jdbc.update("UPDATE evv_outbox SET status='FAILED', last_error=:e, attempts=attempts+1 WHERE id=:id",
                new MapSqlParameterSource().addValue("id", id).addValue("e", err));
    }
}
