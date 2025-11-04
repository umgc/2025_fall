package com.careconnect.service.evv;

import com.careconnect.dto.evv.*;
import com.careconnect.model.evv.*;
import com.careconnect.repository.PatientRepository;
import com.careconnect.repository.evv.EvvCorrectionRepository;
import com.careconnect.repository.evv.EvvOfflineQueueRepository;
import com.careconnect.repository.evv.EvvRecordRepository;
import com.careconnect.repository.schedule.ScheduledVisitRepository;
import com.careconnect.model.schedule.ScheduledVisit;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

@Service @RequiredArgsConstructor
public class EvvService {
    private final EvvRecordRepository recordRepository;
    private final EvvCorrectionRepository correctionRepository;
    private final EvvOfflineQueueRepository offlineQueueRepository;
    private final PatientRepository patientRepository;
    private final EvvLocationService locationService;
    private final AuditLogger audit;
    private final ScheduledVisitRepository scheduledVisitRepository;

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
                // Legacy location fields for backward compatibility
                .locationLat(req.getLocationLat())
                .locationLng(req.getLocationLng())
                .locationSource(req.getLocationSource())
                .status("UNDER_REVIEW")
                .stateCode(req.getStateCode())
                .deviceInfo(req.getDeviceInfo())
                .isOffline(false)
                .eorApprovalRequired(false)
                .isCorrected(false)
                .scheduledVisitId(req.getScheduledVisitId())
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();
        var saved = recordRepository.save(rec); // REQ 2
        audit.log(saved, actorId, "CREATED", null); // REQ 4
        
        // Save check-in and check-out locations using the new location service
        saveLocationsForRecord(saved, req);
        
        // If this EVV record is linked to a scheduled visit, mark the scheduled visit as completed
        if (req.getScheduledVisitId() != null) {
            try {
                var optionalVisit = scheduledVisitRepository.findById(req.getScheduledVisitId());
                if (optionalVisit.isPresent()) {
                    ScheduledVisit scheduledVisit = optionalVisit.get();
                    scheduledVisit.markCompleted();
                    scheduledVisitRepository.save(scheduledVisit);
                } else {
                    // scheduled visit not found — ignore silently
                }
            } catch (Exception e) {
                // Don't fail the EVV record creation if we can't update the scheduled visit
            }
        }
        
        return saved;
    }
    
    /**
     * Convert EvvCorrectionRequestDto to EvvRecordRequestDto for location saving
     */
    private EvvRecordRequestDto convertCorrectionToRecordRequest(EvvCorrectionRequestDto correction, EvvRecord original) {
        return EvvRecordRequestDto.builder()
                .locationLat(correction.getLocationLat())
                .locationLng(correction.getLocationLng())
                .locationSource(correction.getLocationSource())
                .checkinLocationLat(correction.getCheckinLocationLat())
                .checkinLocationLng(correction.getCheckinLocationLng())
                .checkinLocationSource(correction.getCheckinLocationSource())
                .checkoutLocationLat(correction.getCheckoutLocationLat())
                .checkoutLocationLng(correction.getCheckoutLocationLng())
                .checkoutLocationSource(correction.getCheckoutLocationSource())
                .build();
    }
    
    /**
     * Helper method to save check-in and check-out locations for an EVV record
     */
    private void saveLocationsForRecord(EvvRecord record, EvvRecordRequestDto req) {
        // Determine check-in location source
        String checkinSource = req.getCheckinLocationSource();
        
        // Backward compatibility: If using legacy locationSource field, treat it as check-in
        if (checkinSource == null && req.getLocationSource() != null) {
            checkinSource = req.getLocationSource().equalsIgnoreCase("gps") ? "GPS" : "PATIENT_ADDRESS";
        }
        
        // Save check-in location if data is provided
        if (checkinSource != null) {
            try {
                EvvLocationRequest checkinLocationReq = EvvLocationRequest.builder()
                        .evvRecordId(record.getId())
                        .role(EvvLocationRole.CHECK_IN)
                        .type(EvvLocationType.valueOf(checkinSource))
                        .build();
                
                // If GPS, add coordinates (if available)
                if ("GPS".equals(checkinSource)) {
                    Double lat = req.getCheckinLocationLat() != null ? req.getCheckinLocationLat() : req.getLocationLat();
                    Double lng = req.getCheckinLocationLng() != null ? req.getCheckinLocationLng() : req.getLocationLng();
                    
                    if (lat != null && lng != null) {
                        checkinLocationReq.setCoords(EvvLocationRequest.CoordinatesDto.builder()
                                .lat(BigDecimal.valueOf(lat))
                                .lng(BigDecimal.valueOf(lng))
                                .build());
                        // Only save if we have valid coordinates for GPS
                        locationService.saveLocation(checkinLocationReq);
                    } else {
                        System.err.println("Warning: GPS check-in location requested but coordinates not provided");
                    }
                } else {
                    // PATIENT_ADDRESS doesn't need coordinates
                    locationService.saveLocation(checkinLocationReq);
                }
            } catch (Exception e) {
                // Log but don't fail the record creation
                System.err.println("Warning: Failed to save check-in location: " + e.getMessage());
            }
        }
        
        // Save check-out location if data is provided
        if (req.getCheckoutLocationSource() != null) {
            try {
                EvvLocationRequest checkoutLocationReq = EvvLocationRequest.builder()
                        .evvRecordId(record.getId())
                        .role(EvvLocationRole.CHECK_OUT)
                        .type(EvvLocationType.valueOf(req.getCheckoutLocationSource()))
                        .build();
                
                // If GPS, add coordinates (if available)
                if ("GPS".equals(req.getCheckoutLocationSource())) {
                    if (req.getCheckoutLocationLat() != null && req.getCheckoutLocationLng() != null) {
                        checkoutLocationReq.setCoords(EvvLocationRequest.CoordinatesDto.builder()
                                .lat(BigDecimal.valueOf(req.getCheckoutLocationLat()))
                                .lng(BigDecimal.valueOf(req.getCheckoutLocationLng()))
                                .build());
                        // Only save if we have valid coordinates for GPS
                        locationService.saveLocation(checkoutLocationReq);
                    } else {
                        System.err.println("Warning: GPS check-out location requested but coordinates not provided");
                    }
                } else {
                    // PATIENT_ADDRESS doesn't need coordinates
                    locationService.saveLocation(checkoutLocationReq);
                }
            } catch (Exception e) {
                // Log but don't fail the record creation
                System.err.println("Warning: Failed to save check-out location: " + e.getMessage());
            }
        }
    }

    @Transactional
    public EvvRecord review(Long id, boolean approve, Long actorId, String comment){
        var rec = recordRepository.findByIdWithPatient(id).orElseThrow();
        if (approve) {
            rec.markApproved();
        } else {
            rec.markRejected();
        }
        recordRepository.save(rec);
        audit.log(rec, actorId, approve ? "APPROVED" : "REJECTED", null);
        
        // Populate location data before returning
        populateLocationFields(rec);
        
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
                .status("UNDER_REVIEW")
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
        
        // Create corrected record - starts as UNDER_REVIEW since it needs approval
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
                .status("UNDER_REVIEW") // Corrected records need approval
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
        
        // Save location data for corrected record if provided
        saveLocationsForRecord(savedCorrected, convertCorrectionToRecordRequest(req, originalRecord));
        
        // Mark original record as rejected since it was found to be incorrect
        originalRecord.markRejected();
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
        
        audit.log(record, approverId, "EOR_APPROVED", null);
        
        return record;
    }

    public Page<EvvRecord> searchRecords(EvvSearchRequestDto searchRequest) {
        Sort sort = Sort.by(Sort.Direction.fromString(searchRequest.getSortDirection()), searchRequest.getSortBy());
        Pageable pageable = PageRequest.of(searchRequest.getPage(), searchRequest.getSize(), sort);
        
        Page<EvvRecord> records = recordRepository.searchRecords(
            searchRequest.getPatientName(),
            searchRequest.getServiceType(),
            searchRequest.getCaregiverId(),
            searchRequest.getStartDate(),
            searchRequest.getEndDate(),
            searchRequest.getStateCode(),
            searchRequest.getStatus(),
            pageable
        );
        
        // Populate location data from evv_record_location table
        records.forEach(this::populateLocationFields);
        
        return records;
    }
    
    /**
     * Populate check-in and check-out location fields from evv_record_location table
     */
    private void populateLocationFields(EvvRecord record) {
        try {
            List<EvvLocationResponse> locations = locationService.getLocationsForRecord(record.getId());
            
            for (EvvLocationResponse loc : locations) {
                if (loc.getRole() == EvvLocationRole.CHECK_IN) {
                    record.setCheckinLocationLat(loc.getLatitude() != null ? loc.getLatitude().doubleValue() : null);
                    record.setCheckinLocationLng(loc.getLongitude() != null ? loc.getLongitude().doubleValue() : null);
                    record.setCheckinLocationSource(loc.getType().name());
                } else if (loc.getRole() == EvvLocationRole.CHECK_OUT) {
                    record.setCheckoutLocationLat(loc.getLatitude() != null ? loc.getLatitude().doubleValue() : null);
                    record.setCheckoutLocationLng(loc.getLongitude() != null ? loc.getLongitude().doubleValue() : null);
                    record.setCheckoutLocationSource(loc.getType().name());
                }
            }
        } catch (Exception e) {
            // If no locations found, fields will remain null (OK for old records)
        }
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
        
        // Approve the corrected EVV record
        var correctedRecord = correction.getCorrectedRecord();
        correctedRecord.markApproved();
        recordRepository.save(correctedRecord);
        
        audit.log(correctedRecord, approverId, "CORRECTION_APPROVED", null);
        
        return correction;
    }

    @Transactional
    public EvvCorrection rejectCorrection(Long correctionId, Long reviewerId, String comment) {
        var correction = correctionRepository.findById(correctionId)
                .orElseThrow(() -> new IllegalArgumentException("Correction not found"));
        
        correction.reject(reviewerId, comment);
        correctionRepository.save(correction);
        
        // Reject the corrected EVV record
        var correctedRecord = correction.getCorrectedRecord();
        correctedRecord.markRejected();
        recordRepository.save(correctedRecord);
        
        audit.log(correctedRecord, reviewerId, "CORRECTION_REJECTED", null);
        
        return correction;
    }

    public List<EvvOfflineQueue> getOfflineQueue(Long caregiverId) {
        return offlineQueueRepository.findPendingItemsByCaregiver(caregiverId);
    }

}
