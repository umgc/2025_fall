package com.careconnect.model.evv;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
@Entity @Table(name = "evv_participant")
public class EvvParticipant {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "patient_name", nullable = false, length = 200)
    private String patientName;

    @Column(name = "ma_number", nullable = false, unique = true, length = 64)
    private String maNumber;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "created_by", nullable = false)
    private String createdBy;

}
