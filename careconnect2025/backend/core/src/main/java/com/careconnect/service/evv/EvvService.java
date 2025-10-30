package com.careconnect.service.evv;

import com.careconnect.dto.evv.*;
import com.careconnect.model.evv.EvvCorrection;
import com.careconnect.model.evv.EvvOfflineQueue;
import com.careconnect.model.evv.EvvRecord;
import com.careconnect.repository.PatientRepository;
import com.careconnect.repository.evv.EvvCorrectionRepository;
import com.careconnect.repository.evv.EvvOfflineQueueRepository;
import com.careconnect.repository.evv.EvvRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

@Service @RequiredArgsConstructor
public class EvvService {
    private final EvvRecordRepository recordRepository;
    private final EvvCorrectionRepository correctionRepository;
    private final EvvOfflineQueueRepository offlineQueueRepository;
    private final PatientRepository patientRepository;
    private final AuditLogger audit;

    @Transactional
    public EvvRecord createRecord(EvvRecordRequestDto req, Long actorId) {
        var patient = patientRepository.findById(req.getPatientId())
                .orElseThrow(() -> new IllegalArgumentException("Patient not found"));
        
        // Build individual name from patient data
        String individualName = patient.getFirstName() + " " + patient.getLastName();
        
        var rec = EvvRecord.builder()
                .patient(patient)
                .serviceType(req.getServiceType())
                .individualName(individualName)
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
                .isOffline(false)
                .eorApprovalRequired(false)
                .isCorrected(false)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
        var saved = recordRepository.save(rec); // REQ 2
        audit.log(saved, actorId, "CREATED", null); // REQ 4
        return saved;
    }

    @Transactional
    public EvvRecord review(Long id, boolean approve, Long actorId, String comment){
        var rec = recordRepository.findByIdWithPatient(id).orElseThrow();
        if (approve) rec.markConfirmed(); else rec.markPendingReview();
        recordRepository.save(rec);
        audit.log(rec, actorId, approve ? "CONFIRMED" : "REVIEWED", java.util.Map.of("comment", comment)); // REQ 3/4
        return rec;
    }

    @Transactional
    public EvvRecord createOfflineRecord(EvvRecordRequestDto req, Long actorId, String deviceId) {
        var patient = patientRepository.findById(req.getPatientId())
                .orElseThrow(() -> new IllegalArgumentException("Patient not found"));
        
        // Build individual name from patient data
        String individualName = patient.getFirstName() + " " + patient.getLastName();
        
        var rec = EvvRecord.builder()
                .patient(patient)
                .serviceType(req.getServiceType())
                .individualName(individualName)
                .caregiverId(req.getCaregiverId())
                .dateOfService(req.getDateOfService())
                .timeIn(req.getTimeIn())
                .timeOut(req.getTimeOut())
                .locationLat(req.getLocationLat())
                .locationLng(req.getLocationLng())
                .locationSource(req.getLocationSource())
                .status("DRAFT")
                .stateCode(req.getStateCode())
                .deviceInfo(req.getDeviceInfo())
                .isOffline(true)
                .syncStatus("PENDING")
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
        
        var saved = recordRepository.save(rec);
        
        // Add to offline queue
        var queueItem = EvvOfflineQueue.builder()
                .recordId(saved.getId())
                .operationType("CREATE")
                .caregiverId(actorId)
                .deviceId(deviceId)
                .priority(1)
                .recordData(Map.ofEntries(
                    Map.entry("serviceType", req.getServiceType()),
                    Map.entry("individualName", individualName),
                    Map.entry("patientId", req.getPatientId()),
                    Map.entry("dateOfService", req.getDateOfService()),
                    Map.entry("timeIn", req.getTimeIn()),
                    Map.entry("timeOut", req.getTimeOut()),
                    Map.entry("locationLat", req.getLocationLat()),
                    Map.entry("locationLng", req.getLocationLng()),
                    Map.entry("locationSource", req.getLocationSource()),
                    Map.entry("stateCode", req.getStateCode()),
                    Map.entry("deviceInfo", req.getDeviceInfo())
                ))
                .build();
        
        offlineQueueRepository.save(queueItem);
        audit.log(saved, actorId, "OFFLINE_CREATED", Map.of("deviceId", deviceId));
        
        return saved;
    }

    @Transactional
    public EvvRecord correctRecord(EvvCorrectionRequestDto req, Long actorId) {
        var originalRecord = recordRepository.findByIdWithPatient(req.getOriginalRecordId())
                .orElseThrow(() -> new IllegalArgumentException("Original record not found"));
        
        // Create corrected record
        var correctedRecord = EvvRecord.builder()
                .patient(originalRecord.getPatient())
                .serviceType(req.getServiceType() != null ? req.getServiceType() : originalRecord.getServiceType())
                .individualName(req.getIndividualName() != null ? req.getIndividualName() : originalRecord.getIndividualName())
                .caregiverId(originalRecord.getCaregiverId())
                .dateOfService(req.getDateOfService() != null ? req.getDateOfService() : originalRecord.getDateOfService())
                .timeIn(req.getTimeIn() != null ? req.getTimeIn() : originalRecord.getTimeIn())
                .timeOut(req.getTimeOut() != null ? req.getTimeOut() : originalRecord.getTimeOut())
                .locationLat(req.getLocationLat() != null ? req.getLocationLat() : originalRecord.getLocationLat())
                .locationLng(req.getLocationLng() != null ? req.getLocationLng() : originalRecord.getLocationLng())
                .locationSource(req.getLocationSource() != null ? req.getLocationSource() : originalRecord.getLocationSource())
                .status("CORRECTED")
                .stateCode(req.getStateCode() != null ? req.getStateCode() : originalRecord.getStateCode())
                .deviceInfo(req.getDeviceInfo() != null ? req.getDeviceInfo() : originalRecord.getDeviceInfo())
                .isCorrected(true)
                .originalRecordId(originalRecord.getId())
                .correctionReasonCode(req.getReasonCode())
                .correctionExplanation(req.getExplanation())
                .correctedBy(actorId)
                .correctedAt(OffsetDateTime.now())
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
        
        var savedCorrected = recordRepository.save(correctedRecord);
        
        // Mark original as corrected
        originalRecord.markCorrected();
        recordRepository.save(originalRecord);
        
        // Create correction record
        var correction = EvvCorrection.builder()
                .originalRecord(originalRecord)
                .correctedRecord(savedCorrected)
                .reasonCode(req.getReasonCode())
                .explanation(req.getExplanation())
                .correctedBy(actorId)
                .correctedAt(OffsetDateTime.now())
                .approvalRequired(true) // Corrections require approval
                .originalValues(Map.of(
                    "serviceType", originalRecord.getServiceType(),
                    "individualName", originalRecord.getIndividualName(),
                    "dateOfService", originalRecord.getDateOfService(),
                    "timeIn", originalRecord.getTimeIn(),
                    "timeOut", originalRecord.getTimeOut(),
                    "locationLat", originalRecord.getLocationLat(),
                    "locationLng", originalRecord.getLocationLng(),
                    "locationSource", originalRecord.getLocationSource()
                ))
                .correctedValues(Map.of(
                    "serviceType", savedCorrected.getServiceType(),
                    "individualName", savedCorrected.getIndividualName(),
                    "dateOfService", savedCorrected.getDateOfService(),
                    "timeIn", savedCorrected.getTimeIn(),
                    "timeOut", savedCorrected.getTimeOut(),
                    "locationLat", savedCorrected.getLocationLat(),
                    "locationLng", savedCorrected.getLocationLng(),
                    "locationSource", savedCorrected.getLocationSource()
                ))
                .build();
        
        correctionRepository.save(correction);
        
        audit.log(savedCorrected, actorId, "CORRECTED", Map.of(
            "originalRecordId", originalRecord.getId(),
            "reasonCode", req.getReasonCode(),
            "explanation", req.getExplanation()
        ));
        
        return savedCorrected;
    }

    @Transactional
    public EvvRecord approveEor(EorApprovalRequestDto req, Long approverId) {
        var record = recordRepository.findByIdWithPatient(req.getRecordId())
                .orElseThrow(() -> new IllegalArgumentException("Record not found"));
        
        record.approveEor(approverId, req.getComment());
        recordRepository.save(record);
        
        audit.log(record, approverId, "EOR_APPROVED", Map.of("comment", req.getComment()));
        
        return record;
    }

    public Page<EvvRecord> searchRecords(EvvSearchRequestDto searchRequest) {
        Sort sort = Sort.by(Sort.Direction.fromString(searchRequest.getSortDirection()), searchRequest.getSortBy());
        Pageable pageable = PageRequest.of(searchRequest.getPage(), searchRequest.getSize(), sort);
        
        return recordRepository.searchRecords(
            searchRequest.getPatientName(),
            searchRequest.getServiceType(),
            searchRequest.getCaregiverId(),
            searchRequest.getStartDate(),
            searchRequest.getEndDate(),
            searchRequest.getStateCode(),
            searchRequest.getStatus(),
            pageable
        );
    }

    public List<EvvRecord> getPendingEorApprovals() {
        return recordRepository.findPendingEorApprovals();
    }

    public List<EvvCorrection> getPendingCorrections() {
        return correctionRepository.findPendingApprovals();
    }

    @Transactional
    public EvvCorrection approveCorrection(Long correctionId, Long approverId, String comment) {
        var correction = correctionRepository.findById(correctionId)
                .orElseThrow(() -> new IllegalArgumentException("Correction not found"));
        
        correction.approve(approverId, comment);
        correctionRepository.save(correction);
        
        audit.log(correction.getCorrectedRecord(), approverId, "CORRECTION_APPROVED", 
            Map.of("correctionId", correctionId, "comment", comment));
        
        return correction;
    }

    public List<EvvOfflineQueue> getOfflineQueue(Long caregiverId) {
        return offlineQueueRepository.findPendingItemsByCaregiver(caregiverId);
    }

}
