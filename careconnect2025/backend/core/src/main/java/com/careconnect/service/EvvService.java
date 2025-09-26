package com.careconnect.service;

import com.careconnect.dto.CreateParticipationRequestDto;
import com.careconnect.dto.EvvRecordRequestDto;
import com.careconnect.model.*;
import com.careconnect.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service @RequiredArgsConstructor
public class EvvService {
    private final EvvParticipantRepository evvParticipantRepository;
    private final EvvRecordRepository recordRepository;
    private final AuditLogger audit;

    @Transactional
    public EvvParticipant createParticipant(CreateParticipationRequestDto request, String createdBy) {
        var p = evvParticipantRepository.findByMaNumber(request.getMaNumber()).orElse(EvvParticipant.builder()
                .patientName(request.getPatientName())
                .maNumber(request.getMaNumber())
                .createdAt(OffsetDateTime.now())
                .createdBy(createdBy)
                .build());
        return evvParticipantRepository.save(p);
    }

    @Transactional
    public EvvRecord createRecord(EvvRecordRequestDto req, Long actorId) {
        var participant = evvParticipantRepository.findByMaNumber(req.getParticipantMaNumber())
                .orElseThrow(() -> new IllegalArgumentException("Participant not found"));
        var rec = EvvRecord.builder()
                .participant(participant)
                .serviceType(req.getServiceType())
                .individualName(req.getIndividualName())
                .caregiverId(req.getCaregiverId())
                .dateOfService(req.getDateOfService())
                .timeIn(req.getTimeIn())
                .timeOut(req.getTimeOut())
                .locationLat(req.getLocationLat())
                .locationLng(req.getLocationLng())
                .locationSource(req.getLocationSource())
                .status("PENDING_REVIEW")
                .stateCode(req.getStateCode())
                .deviceInfo(req.getDeviceInfo())
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
        var saved = recordRepository.save(rec); // REQ 2
        audit.log(saved, actorId, "CREATED", null); // REQ 4
        return saved;
    }

    @Transactional
    public EvvRecord review(Long id, boolean approve, Long actorId, String comment){
        var rec = recordRepository.findById(id).orElseThrow();
        if (approve) rec.markConfirmed(); else rec.markPendingReview();
        recordRepository.save(rec);
        audit.log(rec, actorId, approve ? "CONFIRMED" : "REVIEWED", java.util.Map.of("comment", comment)); // REQ 3/4
        return rec;
    }

}
