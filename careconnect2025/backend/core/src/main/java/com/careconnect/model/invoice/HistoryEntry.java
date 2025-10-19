package com.careconnect.model.invoice;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@Entity
@Table(name = "invoice_history_entries")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class HistoryEntry {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false, fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id")
    private Invoice invoice;

    private int version;

    @Column(columnDefinition = "text")
    private String changes;

    private String userId;
    private String action;

    @Column(columnDefinition = "text")
    private String details;

    private OffsetDateTime timestamp;
}
