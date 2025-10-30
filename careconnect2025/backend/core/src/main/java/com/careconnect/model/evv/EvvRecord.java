package com.careconnect.model.evv;

import com.careconnect.model.Patient;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.*;
import java.util.Map;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
@Entity @Table(name = "evv_record")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class EvvRecord {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "patient_id")
    private Patient patient; // Direct reference to patient receiving care

    @Column(name = "service_type", nullable = false) private String serviceType;
    @Column(name = "individual_name", nullable = false) private String individualName;
    @Column(name = "caregiver_id", nullable = false) private Long caregiverId;

    @Column(name = "date_of_service", nullable = false) private LocalDate dateOfService;
    @Column(name = "time_in", nullable = false) private OffsetDateTime timeIn;
    @Column(name = "time_out", nullable = false) private OffsetDateTime timeOut;

    @Column(name = "location_lat") private Double locationLat;
    @Column(name = "location_lng") private Double locationLng;
    @Column(name = "location_source") private String locationSource; // gps|manual

    @Column(name = "status", nullable = false) private String status; // DRAFT|PENDING_REVIEW|CONFIRMED|SUBMITTED|FAILED_SUBMISSION|CORRECTED
    @Column(name = "state_code", nullable = false, length = 2) private String stateCode; // MD|DC|VA

    @Convert(disableConversion = true) @Column(name = "device_info", columnDefinition = "jsonb") @JdbcTypeCode(SqlTypes.JSON)
    private Map<String,Object> deviceInfo;

    // Offline support
    @Column(name = "is_offline", nullable = false) private Boolean isOffline = false;
    @Column(name = "sync_status") private String syncStatus; // PENDING|SYNCED|FAILED
    @Column(name = "last_sync_attempt") private OffsetDateTime lastSyncAttempt;

    // EOR approval workflow
    @Column(name = "eor_approval_required", nullable = false) private Boolean eorApprovalRequired = false;
    @Column(name = "eor_approved_by") private Long eorApprovedBy;
    @Column(name = "eor_approved_at") private OffsetDateTime eorApprovedAt;
    @Column(name = "eor_approval_comment") private String eorApprovalComment;

    // Correction support
    @Column(name = "is_corrected", nullable = false) private Boolean isCorrected = false;
    @Column(name = "original_record_id") private Long originalRecordId;
    @Column(name = "correction_reason_code") private String correctionReasonCode;
    @Column(name = "correction_explanation") private String correctionExplanation;
    @Column(name = "corrected_by") private Long correctedBy;
    @Column(name = "corrected_at") private OffsetDateTime correctedAt;

    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private OffsetDateTime updatedAt;

    public void markPendingReview(){ this.status = "PENDING_REVIEW"; this.updatedAt = OffsetDateTime.now(); }
    public void markConfirmed(){ this.status = "CONFIRMED"; this.updatedAt = OffsetDateTime.now(); }
    public void markSubmitted(){ this.status = "SUBMITTED"; this.updatedAt = OffsetDateTime.now(); }
    public void markFailed(){ this.status = "FAILED_SUBMISSION"; this.updatedAt = OffsetDateTime.now(); }
    public void markCorrected(){ this.status = "CORRECTED"; this.updatedAt = OffsetDateTime.now(); }
    
    public void markOffline(){ this.isOffline = true; this.syncStatus = "PENDING"; this.updatedAt = OffsetDateTime.now(); }
    public void markSynced(){ this.isOffline = false; this.syncStatus = "SYNCED"; this.updatedAt = OffsetDateTime.now(); }
    public void markSyncFailed(){ this.syncStatus = "FAILED"; this.lastSyncAttempt = OffsetDateTime.now(); this.updatedAt = OffsetDateTime.now(); }
    
    public void approveEor(Long approverId, String comment) {
        this.eorApprovedBy = approverId;
        this.eorApprovedAt = OffsetDateTime.now();
        this.eorApprovalComment = comment;
        this.updatedAt = OffsetDateTime.now();
    }
    
    public void correctRecord(Long correctorId, String reasonCode, String explanation, Long originalId) {
        this.isCorrected = true;
        this.correctedBy = correctorId;
        this.correctedAt = OffsetDateTime.now();
        this.correctionReasonCode = reasonCode;
        this.correctionExplanation = explanation;
        this.originalRecordId = originalId;
        this.updatedAt = OffsetDateTime.now();
    }
}

