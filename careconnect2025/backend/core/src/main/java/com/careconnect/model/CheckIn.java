// com.careconnect.model.CheckIn
package com.careconnect.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(
  name = "check_ins",
  indexes = @Index(name = "idx_checkins_patient_created", columnList = "patient_id, created_at DESC")
)
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class CheckIn {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  // FK -> patients(id)
  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "patient_id", nullable = false)
  private Patient patient;

  @Column(name = "created_at", nullable = false)
  @Builder.Default
  private OffsetDateTime createdAt = OffsetDateTime.now();

  @Column(name = "submitted_at")
  private OffsetDateTime submittedAt;

  @OneToMany(mappedBy = "checkIn", cascade = CascadeType.ALL, orphanRemoval = true)
  @Builder.Default
  private List<Answer> answers = new ArrayList<>();
}
