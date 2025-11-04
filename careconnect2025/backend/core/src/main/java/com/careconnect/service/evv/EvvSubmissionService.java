package com.careconnect.service.evv;

import com.careconnect.model.evv.EvvRecord;
import com.careconnect.repository.evv.EvvRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service @RequiredArgsConstructor
public class EvvSubmissionService {
    private final List<EvvIntegrationClient> clients;
    private final EvvOutboxService outbox;
    private final EvvRecordRepository evvRecordRepository;
    private final AuditLogger audit;

    public String destinationFor(String stateCode) {
        return switch (stateCode.toUpperCase()) {
            case "MD" -> "maryland-info-only";
            case "DC" -> "dc-sandata";
            case "VA" -> "virginia-mco";
            default -> throw new IllegalArgumentException("Unsupported state code: " + stateCode);
        };
    }

    @Transactional
    public void queueForSubmission(EvvRecord rec, Long actorId) {
        outbox.enqueue(rec, destinationFor(rec.getStateCode()));
        audit.log(rec, actorId, "SUBMISSION_QUEUED", Map.of());
    }
}
