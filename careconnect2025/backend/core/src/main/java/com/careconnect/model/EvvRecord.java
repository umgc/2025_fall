package com.careconnect.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.*;
import java.util.Map;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
@Entity @Table(name = "evv_record")
public class EvvRecord {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "participant_id", nullable = false)
    private EvvParticipant participant;

    @Column(name = "service_type", nullable = false) private String serviceType;
    @Column(name = "individual_name", nullable = false) private String individualName;
    @Column(name = "caregiver_id", nullable = false) private Long caregiverId;

    @Column(name = "date_of_service", nullable = false) private LocalDate dateOfService;
    @Column(name = "time_in", nullable = false) private OffsetDateTime timeIn;
    @Column(name = "time_out", nullable = false) private OffsetDateTime timeOut;

    @Column(name = "location_lat") private Double locationLat;
    @Column(name = "location_lng") private Double locationLng;
    @Column(name = "location_source") private String locationSource; // gps|manual

    @Column(name = "status", nullable = false) private String status; // DRAFT|PENDING_REVIEW|CONFIRMED|SUBMITTED|FAILED_SUBMISSION
    @Column(name = "state_code", nullable = false, length = 2) private String stateCode; // MD|DC|VA

    @Convert(disableConversion = true) @Column(name = "device_info", columnDefinition = "jsonb")
    private Map<String,Object> deviceInfo;

    @Column(name = "created_at", nullable = false) private OffsetDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private OffsetDateTime updatedAt;

    public void markPendingReview(){ this.status = "PENDING_REVIEW"; this.updatedAt = OffsetDateTime.now(); }
    public void markConfirmed(){ this.status = "CONFIRMED"; this.updatedAt = OffsetDateTime.now(); }
    public void markSubmitted(){ this.status = "SUBMITTED"; this.updatedAt = OffsetDateTime.now(); }
    public void markFailed(){ this.status = "FAILED_SUBMISSION"; this.updatedAt = OffsetDateTime.now(); }
}

